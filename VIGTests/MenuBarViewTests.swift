import XCTest
@testable import Vigil

final class MenuBarViewTests: XCTestCase {
    var sut: LockManager!

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            sut = LockManager(
                inputBlockingService: MockInputBlockingService(),
                displayManagerService: MockDisplayManagerService(),
                authenticationService: MockAuthenticationService(),
                sleepPreventionService: MockSleepPreventionService()
            )
        }
    }

    @MainActor
    func testMenuBarIconUnlocked() {
        XCTAssertEqual(sut.menuBarIcon, "lock.open")
    }

    @MainActor
    func testMenuBarIconLockedVisible() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertEqual(sut.menuBarIcon, "lock.fill")
    }

    @MainActor
    func testMenuBarIconLockedObscured() async throws {
        try await sut.lock(mode: .obscured)
        XCTAssertEqual(sut.menuBarIcon, "lock.fill")
    }

    @MainActor
    func testIsLockedTrueWhenLockedVisible() async throws {
        try await sut.lock(mode: .visible)
        XCTAssertTrue(sut.state.isLocked)
    }

    @MainActor
    func testIsLockedFalseWhenUnlocked() {
        XCTAssertFalse(sut.state.isLocked)
    }
}
