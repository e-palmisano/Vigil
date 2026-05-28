import XCTest
@testable import Vigil

final class UnlockWiringTests: XCTestCase {

    @MainActor
    func testOnUnlockCallbackFiredThroughDisplayManager() async throws {
        let display = MockDisplayManagerService()
        let auth = MockAuthenticationService()
        auth.authResult = true
        let sut = LockManager(
            inputBlockingService: MockInputBlockingService(),
            displayManagerService: display,
            authenticationService: auth,
            sleepPreventionService: MockSleepPreventionService()
        )

        try await sut.lock(mode: .obscured)
        XCTAssertEqual(sut.state, .lockedObscured)
        XCTAssertNotNil(display.capturedOnUnlock, "LockManager must wire onUnlock callback")

        // Simulate overlay button tap — fires async unlock internally
        display.capturedOnUnlock?()
        // Yield to allow async Task inside callback to complete
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(sut.state, .unlocked)
    }

    @MainActor
    func testSimulatedShortcutFromInputServiceUnlocksViaLockManager() async throws {
        let inputService = MockInputBlockingService()
        let auth = MockAuthenticationService()
        auth.authResult = true
        let display = MockDisplayManagerService()
        let sut = LockManager(
            inputBlockingService: inputService,
            displayManagerService: display,
            authenticationService: auth,
            sleepPreventionService: MockSleepPreventionService()
        )

        inputService.onUnlockShortcutPressed = { [weak sut] in
            Task { await sut?.unlock() }
        }
        inputService.setUnlockShortcut("cmd+shift+l")

        try await sut.lock(mode: .visible)
        XCTAssertEqual(sut.state, .lockedVisible)

        inputService.simulateUnlockShortcut()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(sut.state, .unlocked)
    }

    @MainActor
    func testUnlockFailedAuthKeepsLockedState() async throws {
        let display = MockDisplayManagerService()
        let auth = MockAuthenticationService()
        auth.authResult = false
        let sut = LockManager(
            inputBlockingService: MockInputBlockingService(),
            displayManagerService: display,
            authenticationService: auth,
            sleepPreventionService: MockSleepPreventionService()
        )

        try await sut.lock(mode: .obscured)
        XCTAssertEqual(sut.state, .lockedObscured)

        await sut.unlock()

        XCTAssertEqual(sut.state, .lockedObscured)
    }
}
