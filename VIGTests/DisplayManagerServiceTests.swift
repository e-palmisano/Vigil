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

    func testCreateBadgeWindowSetsFlag() {
        let svc = MockDisplayManagerService()
        svc.createBadgeWindow(position: .bottomRight, isTouchIDAvailable: true, onUnlock: {})
        XCTAssertTrue(svc.hasBadgeWindow)
        XCTAssertEqual(svc.createBadgeCallCount, 1)
    }

    func testCreateBadgeWindowRecordsPosition() {
        let svc = MockDisplayManagerService()
        svc.createBadgeWindow(position: .center, isTouchIDAvailable: false, onUnlock: {})
        XCTAssertEqual(svc.lastBadgePosition, .center)
    }

    func testRemoveBadgeWindowClearsFlag() {
        let svc = MockDisplayManagerService()
        svc.createBadgeWindow(position: .bottomRight, isTouchIDAvailable: true, onUnlock: {})
        svc.removeBadgeWindow()
        XCTAssertFalse(svc.hasBadgeWindow)
        XCTAssertEqual(svc.removeBadgeCallCount, 1)
    }

    func testRemoveAllOverlayWindowsAlsoRemovesBadge() {
        let svc = MockDisplayManagerService()
        svc.createBadgeWindow(position: .bottomRight, isTouchIDAvailable: false, onUnlock: {})
        svc.removeAllOverlayWindows()
        XCTAssertFalse(svc.hasBadgeWindow)
    }

    func testAuthenticationModeRecordedAndClearedOnRemove() {
        let svc = MockDisplayManagerService()
        svc.createOverlayWindows(style: .darkDimmed, mode: .obscured, isTouchIDAvailable: false, onUnlock: {})
        svc.setAuthenticationMode(true)
        XCTAssertTrue(svc.authenticationModeActive)
        svc.removeAllOverlayWindows()
        XCTAssertFalse(svc.authenticationModeActive)
        XCTAssertEqual(svc.authenticationModeChanges, [true])
    }
}
