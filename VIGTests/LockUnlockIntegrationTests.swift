import XCTest
@testable import Vigil

@MainActor
final class LockUnlockIntegrationTests: XCTestCase {
    var sut: LockManager!
    var inputBlocking: MockInputBlockingService!
    var displayManager: MockDisplayManagerService!
    var authentication: MockAuthenticationService!
    var sleepPrevention: MockSleepPreventionService!

    override func setUp() {
        super.setUp()
        inputBlocking = MockInputBlockingService()
        displayManager = MockDisplayManagerService()
        authentication = MockAuthenticationService()
        sleepPrevention = MockSleepPreventionService()
        sut = LockManager(
            inputBlockingService: inputBlocking,
            displayManagerService: displayManager,
            authenticationService: authentication,
            sleepPreventionService: sleepPrevention
        )
    }

    func test_fullFlow_lockObscured_authSuccess_unlock() async throws {
        try await sut.lock(mode: .obscured)
        XCTAssertEqual(sut.state, .lockedObscured)
        XCTAssertTrue(inputBlocking.isBlocking)
        XCTAssertTrue(displayManager.hasOverlays)

        authentication.authResult = true
        await sut.unlock()
        XCTAssertEqual(sut.state, .unlocked)
        XCTAssertFalse(inputBlocking.isBlocking)
        XCTAssertFalse(displayManager.hasOverlays)
    }

    func test_fullFlow_lockVisible_authFail_staysLocked() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertEqual(sut.state, .lockedVisible)

        authentication.authResult = false
        await sut.unlock()
        XCTAssertEqual(sut.state, .lockedVisible)
        XCTAssertTrue(inputBlocking.isBlocking)
    }

    func test_fullFlow_lockObscured_authCancelled_staysLocked() async throws {
        try await sut.lock(mode: .obscured)
        authentication.shouldThrow = AuthenticationError.cancelled
        await sut.unlock()
        XCTAssertEqual(sut.state, .lockedObscured)
    }

    func test_fullFlow_eventTapDisabled_recoversToUnlocked() async throws {
        try await sut.lock(mode: .obscured)
        XCTAssertEqual(sut.state, .lockedObscured)

        inputBlocking.onEventTapDisabled?()

        // Recovery fires after 500ms
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(sut.state, .unlocked)
    }

    func test_emergencyUnlock_recoversFromAnyLockedState() async throws {
        try await sut.lock(mode: .obscured)
        sut.emergencyUnlock()
        XCTAssertEqual(sut.state, .unlocked)
        XCTAssertFalse(inputBlocking.isBlocking)
        XCTAssertFalse(displayManager.hasOverlays)
        XCTAssertEqual(sleepPrevention.allowCallCount, 1)
    }

    func test_cannotLockWhileAlreadyLocked() async throws {
        try await sut.lock(mode: .obscured)
        let createCountAfterFirstLock = displayManager.createCallCount

        try? await sut.lock(mode: .visible)
        XCTAssertEqual(displayManager.createCallCount, createCountAfterFirstLock)
    }
}
