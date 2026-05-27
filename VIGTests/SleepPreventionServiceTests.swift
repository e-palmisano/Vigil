import XCTest
import IOKit.pwr_mgt
@testable import Vigil

final class SleepPreventionServiceTests: XCTestCase {

    func testMockPreventSleepIncrementsCount() throws {
        let svc = MockSleepPreventionService()
        _ = try svc.preventSleep(reason: "test")
        XCTAssertEqual(svc.preventCallCount, 1)
    }

    func testMockPreventSleepReturnsDistinctIDs() throws {
        let svc = MockSleepPreventionService()
        let id1 = try svc.preventSleep(reason: "test1")
        let id2 = try svc.preventSleep(reason: "test2")
        XCTAssertNotEqual(id1, id2)
    }

    func testMockAllowSleepIncrementsCount() throws {
        let svc = MockSleepPreventionService()
        let id = try svc.preventSleep(reason: "test")
        svc.allowSleep(assertionID: id)
        XCTAssertEqual(svc.allowCallCount, 1)
    }

    func testMockPreventSleepThrowsWhenConfigured() {
        let svc = MockSleepPreventionService()
        svc.shouldThrow = SleepPreventionError.assertionFailed(kIOReturnNotPermitted)
        XCTAssertThrowsError(try svc.preventSleep(reason: "test"))
    }
}
