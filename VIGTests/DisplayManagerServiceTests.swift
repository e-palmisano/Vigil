import XCTest
@testable import Vigil

final class DisplayManagerServiceTests: XCTestCase {

    func testMockCreateSetsHasOverlays() {
        let svc = MockDisplayManagerService()
        svc.createOverlayWindows(style: .darkDimmed, mode: .obscured, isTouchIDAvailable: false, onUnlock: {})
        XCTAssertTrue(svc.hasOverlays)
        XCTAssertEqual(svc.createCallCount, 1)
    }

    func testMockRemoveClearsHasOverlays() {
        let svc = MockDisplayManagerService()
        svc.createOverlayWindows(style: .darkDimmed, mode: .obscured, isTouchIDAvailable: false, onUnlock: {})
        svc.removeAllOverlayWindows()
        XCTAssertFalse(svc.hasOverlays)
        XCTAssertEqual(svc.removeCallCount, 1)
    }

    func testMockUpdateStyleRecordsStyle() {
        let svc = MockDisplayManagerService()
        svc.updateStyle(.blueGradient)
        XCTAssertEqual(svc.lastStyle, .blueGradient)
    }

    func testMockCapturesOnUnlockCallback() {
        let svc = MockDisplayManagerService()
        var fired = false
        svc.createOverlayWindows(style: .darkDimmed, mode: .obscured, isTouchIDAvailable: true, onUnlock: { fired = true })
        svc.capturedOnUnlock?()
        XCTAssertTrue(fired)
    }

    func testMockRecordsLastMode() {
        let svc = MockDisplayManagerService()
        svc.createOverlayWindows(style: .darkDimmed, mode: .visible, isTouchIDAvailable: false, onUnlock: {})
        XCTAssertEqual(svc.lastMode, .visible)
    }
}
