import Foundation
import CoreGraphics

protocol InputBlockingServiceProtocol: AnyObject {
    var isBlocking: Bool { get }
    var onEventTapDisabled: (() -> Void)? { get set }
    var onUnlockShortcutPressed: (() -> Void)? { get set }

    /// Fired after the emergency combo has been held for the full hold
    /// duration. Detected inside the event tap because NSEvent global
    /// monitors never see events the tap has already eaten.
    var onEmergencyShortcutHeld: (() -> Void)? { get set }

    func startBlocking(mode: LockMode) throws
    func stopBlocking()
    func checkAccessibilityPermission() -> Bool
    func requestAccessibilityPermission()
    func setUnlockShortcut(_ shortcutString: String?)
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
