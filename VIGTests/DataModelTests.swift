import XCTest
@testable import Vigil

final class DataModelTests: XCTestCase {

    func testLockStateEquality() {
        XCTAssertEqual(LockState.unlocked, .unlocked)
        XCTAssertEqual(LockState.error("foo"), .error("foo"))
        XCTAssertNotEqual(LockState.error("foo"), .error("bar"))
        XCTAssertNotEqual(LockState.unlocked, .locking)
    }

    func testLockStateIsLocked() {
        XCTAssertTrue(LockState.lockedVisible.isLocked)
        XCTAssertTrue(LockState.lockedObscured.isLocked)
        XCTAssertFalse(LockState.unlocked.isLocked)
        XCTAssertFalse(LockState.locking.isLocked)
        XCTAssertFalse(LockState.unlocking.isLocked)
        XCTAssertFalse(LockState.error("x").isLocked)
    }

    func testLockModeCodable() throws {
        let data = try JSONEncoder().encode(LockMode.visible)
        let decoded = try JSONDecoder().decode(LockMode.self, from: data)
        XCTAssertEqual(decoded, .visible)
    }

    func testOverlayStyleAllCases() {
        XCTAssertEqual(OverlayStyle.allCases.count, 5)
    }

    func testOverlayStyleIdentifiable() {
        XCTAssertEqual(OverlayStyle.darkDimmed.id, "darkDimmed")
    }

    func testBadgePositionAllCases() {
        XCTAssertEqual(BadgePosition.allCases.count, 5)
    }
}
