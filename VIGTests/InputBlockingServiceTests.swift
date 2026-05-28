import XCTest
@testable import Vigil

final class InputBlockingServiceTests: XCTestCase {

    func testMockStartBlockingSetsIsBlocking() throws {
        let svc = MockInputBlockingService()
        try svc.startBlocking()
        XCTAssertTrue(svc.isBlocking)
    }

    func testMockStopBlockingClearsIsBlocking() throws {
        let svc = MockInputBlockingService()
        try svc.startBlocking()
        svc.stopBlocking()
        XCTAssertFalse(svc.isBlocking)
    }

    func testMockThrowsWhenConfigured() {
        let svc = MockInputBlockingService()
        svc.shouldThrow = InputBlockingError.eventTapCreationFailed
        XCTAssertThrowsError(try svc.startBlocking())
    }

    func testMockPermissionDeniedThrows() {
        let svc = MockInputBlockingService()
        svc.permissionGranted = false
        XCTAssertFalse(svc.checkAccessibilityPermission())
    }

    func testMockOnEventTapDisabledCallback() throws {
        let svc = MockInputBlockingService()
        try svc.startBlocking()
        var callbackFired = false
        svc.onEventTapDisabled = { callbackFired = true }
        svc.simulateEventTapDisabled()
        XCTAssertTrue(callbackFired)
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
