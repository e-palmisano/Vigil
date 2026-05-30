import XCTest
import Combine
@testable import Vigil

final class LockManagerTests: XCTestCase {
    var inputService: MockInputBlockingService!
    var displayService: MockDisplayManagerService!
    var authService: MockAuthenticationService!
    var sleepService: MockSleepPreventionService!
    var sut: LockManager!

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            inputService = MockInputBlockingService()
            displayService = MockDisplayManagerService()
            authService = MockAuthenticationService()
            authService.isTouchIDAvailable = false
            sleepService = MockSleepPreventionService()
            sut = LockManager(
                inputBlockingService: inputService,
                displayManagerService: displayService,
                authenticationService: authService,
                sleepPreventionService: sleepService
            )
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            sut?.emergencyUnlock()
        }
        try await super.tearDown()
    }

    @MainActor
    func testInitialStateIsUnlocked() {
        XCTAssertEqual(sut.state, .unlocked)
    }

    @MainActor
    func testLockVisibleTransitionsToLockedVisible() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertEqual(sut.state, .lockedVisible)
        XCTAssertTrue(inputService.isBlocking)
    }

    @MainActor
    func testLockObscuredTransitionsToLockedObscured() async throws {
        try await sut.lock(mode: .obscured)
        XCTAssertEqual(sut.state, .lockedObscured)
        XCTAssertTrue(inputService.isBlocking)
        XCTAssertEqual(displayService.createCallCount, 1)
    }

    @MainActor
    func testLockWhenNoAccessibilityPermissionThrows() async {
        inputService.permissionGranted = false
        do {
            try await sut.lock(mode: .visible)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(sut.state, .unlocked)
        }
    }

    @MainActor
    func testUnlockSuccessReturnsToUnlocked() async throws {
        try await sut.lock(mode: .visible)
        authService.authResult = true
        await sut.unlock()
        XCTAssertEqual(sut.state, .unlocked)
        XCTAssertFalse(inputService.isBlocking)
    }

    @MainActor
    func testUnlockFailureRemainsLocked() async throws {
        try await sut.lock(mode: .visible)
        authService.authResult = false
        await sut.unlock()
        XCTAssertEqual(sut.state, .lockedVisible)
        XCTAssertTrue(inputService.isBlocking)
        XCTAssertTrue(displayService.hasBadgeWindow)
    }

    @MainActor
    func testEmergencyUnlockAlwaysSucceeds() async throws {
        try await sut.lock(mode: .visible)
        authService.authResult = false
        sut.emergencyUnlock()
        XCTAssertEqual(sut.state, .unlocked)
    }

    @MainActor
    func testPreventSleepCalledWhenEnabled() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertEqual(sleepService.preventCallCount, 1)
    }

    @MainActor
    func testAllowSleepCalledOnUnlock() async throws {
        try await sut.lock(mode: .visible)
        authService.authResult = true
        await sut.unlock()
        XCTAssertEqual(sleepService.allowCallCount, 1)
    }

    @MainActor
    func testSwitchModeFromVisibleToObscured() async throws {
        try await sut.lock(mode: .visible)
        await sut.switchMode(to: .obscured)
        XCTAssertEqual(sut.state, .lockedObscured)
        XCTAssertEqual(displayService.createCallCount, 1)
    }

    @MainActor
    func testSwitchModeFromObscuredToVisibleCreatesBadgeWindow() async throws {
        try await sut.lock(mode: .obscured)
        await sut.switchMode(to: .visible)
        XCTAssertEqual(sut.state, .lockedVisible)
        XCTAssertFalse(displayService.hasOverlays)
        XCTAssertTrue(displayService.hasBadgeWindow)
    }

    @MainActor
    func testMenuBarIconUnlocked() {
        XCTAssertEqual(sut.menuBarIcon, "lock.open")
    }

    @MainActor
    func testMenuBarIconLocked() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertEqual(sut.menuBarIcon, "lock.fill")
    }

    @MainActor
    func testLockVisibleCreatesBadgeWindow() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertTrue(displayService.hasBadgeWindow)
        XCTAssertEqual(displayService.createBadgeCallCount, 1)
    }

    @MainActor
    func testUnlockShortcutCallbackTriggersUnlock() async throws {
        authService.authResult = true
        try await sut.lock(mode: .visible)
        inputService.simulateUnlockShortcut()
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(sut.state, .unlocked)
    }

    @MainActor
    func testBadgeWindowRemovedOnUnlock() async throws {
        authService.authResult = true
        try await sut.lock(mode: .visible)
        await sut.unlock()
        XCTAssertFalse(displayService.hasBadgeWindow)
    }

    // MARK: - Interactive rects pushed to the input service

    @MainActor
    func testLockPushesWindowFramesToInputServiceAsInteractiveRects() async throws {
        let badgeFrame = CGRect(x: 1644, y: 16, width: 260, height: 96)
        displayService.stubbedInteractiveFrames = [badgeFrame]

        try await sut.lock(mode: .visible)

        XCTAssertEqual(inputService.interactiveRects, [badgeFrame])
        XCTAssertGreaterThanOrEqual(inputService.setInteractiveRectsCallCount, 1)
    }

    // MARK: - Unlock authentication presentation

    @MainActor
    func testLockDoesNotAutomaticallyPromptForTouchIDAndKeepsLockPresentationVisible() async throws {
        authService.isTouchIDAvailable = true

        try await sut.lock(mode: .obscured)
        try? await Task.sleep(nanoseconds: 60_000_000)

        XCTAssertEqual(authService.biometricsOnlyCallCount, 0)
        XCTAssertEqual(authService.callCount, 0)
        XCTAssertEqual(sut.state, .lockedObscured)
        XCTAssertTrue(inputService.isBlocking)
        XCTAssertTrue(displayService.hasOverlays)
    }

    @MainActor
    func testObscuredUnlockSuspendsOverlayAndInputBeforeSystemAuthentication() async throws {
        try await sut.lock(mode: .obscured)
        authService.authResult = true
        authService.onAuthenticate = { [weak self] in
            guard let self else { return }
            XCTAssertFalse(self.inputService.isBlocking)
            XCTAssertFalse(self.displayService.hasOverlays)
        }

        await sut.unlock()

        XCTAssertEqual(sut.state, .unlocked)
        XCTAssertFalse(inputService.isBlocking)
        XCTAssertFalse(displayService.hasOverlays)
    }

    @MainActor
    func testObscuredUnlockFailureRestoresOverlayAndInputBlocking() async throws {
        try await sut.lock(mode: .obscured)
        authService.authResult = false

        await sut.unlock()

        XCTAssertEqual(sut.state, .lockedObscured)
        XCTAssertTrue(inputService.isBlocking)
        XCTAssertTrue(displayService.hasOverlays)
        XCTAssertEqual(inputService.startCallCount, 2)
        XCTAssertEqual(displayService.createCallCount, 2)
    }
}
