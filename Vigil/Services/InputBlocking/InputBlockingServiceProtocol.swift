import Foundation
import CoreGraphics

protocol InputBlockingServiceProtocol: AnyObject {
    var isBlocking: Bool { get }
    var onEventTapDisabled: (() -> Void)? { get set }
    var onUnlockShortcutPressed: (() -> Void)? { get set }
    var onEmergencyUnlockPressed: (() -> Void)? { get set }
    func startBlocking(mode: LockMode) throws
    func stopBlocking()
    func checkAccessibilityPermission() -> Bool
    func requestAccessibilityPermission()
    func setUnlockShortcut(_ shortcutString: String?)

    /// The emergency-unlock shortcut, detected inside the HID event tap so it
    /// fires even while input is blocked (a global `NSEvent` monitor cannot —
    /// the tap consumes the events before they reach it).
    func setEmergencyShortcut(_ shortcutString: String?)

    /// Regions where mouse clicks are allowed through to Vigil's own windows.
    /// Rects are in Cocoa global coordinates (origin bottom-left); the service
    /// converts them to CoreGraphics event coordinates internally.
    func setInteractiveRects(_ rects: [CGRect])
}

enum InputBlockingError: Error {
    case accessibilityPermissionDenied
    case eventTapCreationFailed
}
