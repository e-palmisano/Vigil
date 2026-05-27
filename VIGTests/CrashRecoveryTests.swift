import XCTest
@testable import Vigil

final class CrashRecoveryTests: XCTestCase {

    @MainActor
    func testPersistStateForCrashRecoveryWritesLockedObscured() async throws {
        let settings = AppSettings()
        settings.wasLockedOnExit = false
        let sut = LockManager(
            inputBlockingService: MockInputBlockingService(),
            displayManagerService: MockDisplayManagerService(),
            authenticationService: MockAuthenticationService(),
            sleepPreventionService: MockSleepPreventionService(),
            settings: settings
        )
        try await sut.lock(mode: .obscured)
        XCTAssertTrue(settings.wasLockedOnExit)
        XCTAssertEqual(settings.lockModeOnExit, LockMode.obscured.rawValue)
    }

    @MainActor
    func testPersistStateForCrashRecoveryWritesLockedVisible() async throws {
        let settings = AppSettings()
        settings.wasLockedOnExit = false
        let sut = LockManager(
            inputBlockingService: MockInputBlockingService(),
            displayManagerService: MockDisplayManagerService(),
            authenticationService: MockAuthenticationService(),
            sleepPreventionService: MockSleepPreventionService(),
            settings: settings
        )
        try await sut.lock(mode: .visible)
        XCTAssertTrue(settings.wasLockedOnExit)
        XCTAssertEqual(settings.lockModeOnExit, LockMode.visible.rawValue)
    }

    @MainActor
    func testPersistStateForCrashRecoveryClearsOnUnlock() async throws {
        let settings = AppSettings()
        let auth = MockAuthenticationService()
        auth.authResult = true
        let sut = LockManager(
            inputBlockingService: MockInputBlockingService(),
            displayManagerService: MockDisplayManagerService(),
            authenticationService: auth,
            sleepPreventionService: MockSleepPreventionService(),
            settings: settings
        )
        try await sut.lock(mode: .visible)
        XCTAssertTrue(settings.wasLockedOnExit)
        await sut.unlock()
        XCTAssertFalse(settings.wasLockedOnExit)
    }
}
