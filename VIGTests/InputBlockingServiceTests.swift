import XCTest
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
}
