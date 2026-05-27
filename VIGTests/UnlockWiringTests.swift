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
