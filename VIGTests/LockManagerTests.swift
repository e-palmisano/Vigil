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
    func testObscuredUnlockStopsTapButKeepsOverlaysBelowSystemAuthentication() async throws {
        try await sut.lock(mode: .obscured)
        authService.authResult = true
        authService.onAuthenticate = { [weak self] in
            guard let self else { return }
            // The tap must stop so the prompt receives the password, but the
            // overlays stay up (below the prompt) so the screen stays covered.
            XCTAssertFalse(self.inputService.isBlocking)
            XCTAssertTrue(self.displayService.hasOverlays)
            XCTAssertTrue(self.displayService.authenticationModeActive)
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
        XCTAssertFalse(displayService.authenticationModeActive)
        XCTAssertEqual(inputService.startCallCount, 2)
        // Overlays are never torn down during auth — only re-leveled.
        XCTAssertEqual(displayService.createCallCount, 1)
    }

    @MainActor
    func testRestoreLockFailureUnlocksFullyInsteadOfHalfLocked() async throws {
        try await sut.lock(mode: .obscured)
        authService.authResult = false
        inputService.shouldThrow = InputBlockingError.eventTapCreationFailed

        await sut.unlock()

        // Re-arming the tap failed: everything must be torn down, the sleep
        // assertion released, and the error surfaced transiently.
        XCTAssertEqual(sut.state, .error("eventTapCreationFailed"))
        XCTAssertFalse(displayService.hasOverlays)
        XCTAssertEqual(sleepService.allowCallCount, 1)

        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(sut.state, .unlocked)
    }

    @MainActor
    func testEmergencyShortcutHeldCallbackUnlocksWithoutAuthentication() async throws {
        try await sut.lock(mode: .obscured)
        authService.authResult = false

        inputService.simulateEmergencyShortcutHeld()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.state, .unlocked)
        XCTAssertEqual(authService.callCount, 0)
        XCTAssertFalse(inputService.isBlocking)
    }

    @MainActor
    func testLockVisiblePassesConfiguredBadgePosition() async throws {
        let settings = AppSettings()
        settings.badgePosition = BadgePosition.topLeft.rawValue
        defer { settings.badgePosition = BadgePosition.bottomRight.rawValue }
        let manager = LockManager(
            inputBlockingService: MockInputBlockingService(),
            displayManagerService: displayService,
            authenticationService: authService,
            sleepPreventionService: MockSleepPreventionService(),
            settings: settings
        )

        try await manager.lock(mode: .visible)

        XCTAssertEqual(displayService.lastBadgePosition, .topLeft)
        manager.emergencyUnlock()
    }

    @MainActor
    func testChangingOverlayStyleWhileLockedUpdatesOverlays() async throws {
        let settings = AppSettings()
        settings.overlayStyle = OverlayStyle.darkDimmed.rawValue
        let manager = LockManager(
            inputBlockingService: MockInputBlockingService(),
            displayManagerService: displayService,
            authenticationService: authService,
            sleepPreventionService: MockSleepPreventionService(),
            settings: settings
        )
        try await manager.lock(mode: .obscured)

        settings.overlayStyle = OverlayStyle.minimalBlack.rawValue
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(displayService.lastStyle, .minimalBlack)
        manager.emergencyUnlock()
    }

    @MainActor
    func testEventTapDisabledTearsDownPresentation() async throws {
        try await sut.lock(mode: .obscured)

        inputService.simulateEventTapDisabled()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Input is no longer blocked, so the overlays must not fake a lock.
        XCTAssertFalse(displayService.hasOverlays)
        XCTAssertEqual(sleepService.allowCallCount, 1)
    }
}
