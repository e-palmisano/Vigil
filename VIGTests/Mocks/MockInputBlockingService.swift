import Foundation
import CoreGraphics
@testable import Vigil

final class MockInputBlockingService: InputBlockingServiceProtocol {
    var isBlocking: Bool = false
    var onEventTapDisabled: (() -> Void)?
    var onUnlockShortcutPressed: (() -> Void)?
    var onEmergencyUnlockPressed: (() -> Void)?
    var shouldThrow: Error?
    var startCallCount: Int = 0
    var stopCallCount: Int = 0
    var permissionGranted: Bool = true
    var storedShortcut: String?
    var storedEmergencyShortcut: String?

    var lastBlockingMode: LockMode?

    var interactiveRects: [CGRect] = []
    var setInteractiveRectsCallCount: Int = 0

    func startBlocking(mode: LockMode) throws {
        lastBlockingMode = mode
        startCallCount += 1
        if let error = shouldThrow { throw error }
        isBlocking = true
    }

    func stopBlocking() {
        stopCallCount += 1
        isBlocking = false
    }

    func checkAccessibilityPermission() -> Bool { permissionGranted }
    func requestAccessibilityPermission() {}

    func setUnlockShortcut(_ shortcutString: String?) {
        storedShortcut = shortcutString
    }

    func setEmergencyShortcut(_ shortcutString: String?) {
        storedEmergencyShortcut = shortcutString
    }

    func setInteractiveRects(_ rects: [CGRect]) {
        setInteractiveRectsCallCount += 1
        interactiveRects = rects
    }

    func simulateEventTapDisabled() {
        onEventTapDisabled?()
    }

    func simulateUnlockShortcut() {
        onUnlockShortcutPressed?()
    }

    func simulateEmergencyUnlock() {
        onEmergencyUnlockPressed?()
    }
}
