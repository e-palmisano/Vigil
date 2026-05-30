import XCTest
import CoreGraphics
@testable import Vigil

final class InputBlockingServiceTests: XCTestCase {

    func testMockStartBlockingSetsIsBlocking() throws {
        let svc = MockInputBlockingService()
        try svc.startBlocking(mode: .obscured)
        XCTAssertTrue(svc.isBlocking)
    }

    func testMockStopBlockingClearsIsBlocking() throws {
        let svc = MockInputBlockingService()
        try svc.startBlocking(mode: .obscured)
        svc.stopBlocking()
        XCTAssertFalse(svc.isBlocking)
    }

    func testMockThrowsWhenConfigured() {
        let svc = MockInputBlockingService()
        svc.shouldThrow = InputBlockingError.eventTapCreationFailed
        XCTAssertThrowsError(try svc.startBlocking(mode: .obscured))
    }

    func testMockPermissionDeniedThrows() {
        let svc = MockInputBlockingService()
        svc.permissionGranted = false
        XCTAssertFalse(svc.checkAccessibilityPermission())
    }

    func testMockOnEventTapDisabledCallback() throws {
        let svc = MockInputBlockingService()
        try svc.startBlocking(mode: .obscured)
        var callbackFired = false
        svc.onEventTapDisabled = { callbackFired = true }
        svc.simulateEventTapDisabled()
        XCTAssertTrue(callbackFired)
    }

    func testMockVisibleModeDoesNotBlockMouse() throws {
        let svc = MockInputBlockingService()
        try svc.startBlocking(mode: .visible)
        XCTAssertTrue(svc.isBlocking)
        XCTAssertEqual(svc.lastBlockingMode, .visible)
    }

    @MainActor
    func testSimulateUnlockShortcutFiresCallback() {
        let mock = MockInputBlockingService()
        var fired = false
        mock.onUnlockShortcutPressed = { fired = true }
        mock.simulateUnlockShortcut()
        XCTAssertTrue(fired)
    }

    @MainActor
    func testSetUnlockShortcutStoredOnMock() {
        let mock = MockInputBlockingService()
        mock.setUnlockShortcut("cmd+shift+l")
        XCTAssertEqual(mock.storedShortcut, "cmd+shift+l")
    }

    // MARK: - Real service event mask tests

    func testObscuredModeEventMaskPassesMovementButInterceptsClicks() {
        let mask = InputBlockingService.eventMask(for: .obscured)
        // Movement/drag must pass through so hover reveals chrome and the
        // overlay can auto-hide; these are NOT in the mask.
        let movement: [CGEventType] = [
            .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged
        ]
        for event in movement {
            let bit = CGEventMask(1) << event.rawValue
            XCTAssertEqual(mask & bit, 0, "Mouse movement \(event) should pass through")
        }
        // Clicks MUST be intercepted so the tap can allow only the unlock area.
        let clicks: [CGEventType] = [
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp
        ]
        for event in clicks {
            let bit = CGEventMask(1) << event.rawValue
            XCTAssertNotEqual(mask & bit, 0, "Mouse click \(event) must be intercepted")
        }
    }

    func testObscuredModeEventMaskIncludesKeyboardAndScroll() {
        let mask = InputBlockingService.eventMask(for: .obscured)
        let requiredEvents: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .scrollWheel]
        for event in requiredEvents {
            let bit = CGEventMask(1) << event.rawValue
            XCTAssertNotEqual(mask & bit, 0, "Event \(event) should be blocked in obscured mode")
        }
    }

    func testVisibleModeEventMaskPassesMovementButInterceptsClicks() {
        let mask = InputBlockingService.eventMask(for: .visible)
        let moveBit = CGEventMask(1) << CGEventType.mouseMoved.rawValue
        XCTAssertEqual(mask & moveBit, 0, "Mouse movement should pass through in visible mode")

        let clicks: [CGEventType] = [.leftMouseDown, .leftMouseUp]
        for event in clicks {
            let bit = CGEventMask(1) << event.rawValue
            XCTAssertNotEqual(mask & bit, 0, "Mouse click \(event) must be intercepted in visible mode")
        }
    }

    func testVisibleModeEventMaskIncludesKeyboardAndScroll() {
        let mask = InputBlockingService.eventMask(for: .visible)
        let requiredEvents: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .scrollWheel]
        for event in requiredEvents {
            let bit = CGEventMask(1) << event.rawValue
            XCTAssertNotEqual(mask & bit, 0, "Event \(event) should be blocked in visible mode")
        }
    }

    // MARK: - Coordinate flip (regression for the unclickable-badge bug)

    func testGlobalCGRectFlipsCocoaBottomLeftToCGTopLeft() {
        // A badge near the visual bottom of a 1080-tall primary display:
        // Cocoa y is small (origin bottom-left). After the flip it must sit
        // near the bottom in CGEvent space (origin top-left), i.e. large y.
        let cocoa = CGRect(x: 1644, y: 16, width: 260, height: 96)
        let cg = InputBlockingService.globalCGRect(from: cocoa, primaryHeight: 1080)

        XCTAssertEqual(cg.minX, 1644, accuracy: 0.001, "x must not change")
        XCTAssertEqual(cg.width, 260, accuracy: 0.001)
        XCTAssertEqual(cg.height, 96, accuracy: 0.001)
        // Cocoa maxY = 112 → CG minY = 1080 - 112 = 968
        XCTAssertEqual(cg.minY, 968, accuracy: 0.001, "y must flip about the primary height")
    }

    func testFlippedRectMatchesBottomScreenClickNotTopScreenClick() {
        let cocoa = CGRect(x: 1644, y: 16, width: 260, height: 96)
        let cg = InputBlockingService.globalCGRect(from: cocoa, primaryHeight: 1080)
        // A real click on the bottom-right badge lands at a large CGEvent y.
        XCTAssertTrue(cg.contains(CGPoint(x: 1700, y: 1000)), "bottom-screen click should hit the badge")
        // The pre-fix bug accepted clicks near the TOP of the screen instead.
        XCTAssertFalse(cg.contains(CGPoint(x: 1700, y: 100)), "top-screen click must NOT hit the badge")
    }
}
