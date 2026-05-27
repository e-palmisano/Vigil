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
            sleepService = MockSleepPreventionService()
            sut = LockManager(
                inputBlockingService: inputService,
                displayManagerService: displayService,
                authenticationService: authService,
                sleepPreventionService: sleepService
            )
        }
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
    func testMenuBarIconUnlocked() {
        XCTAssertEqual(sut.menuBarIcon, "lock.open")
    }

    @MainActor
    func testMenuBarIconLocked() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertEqual(sut.menuBarIcon, "lock.fill")
    }
}
