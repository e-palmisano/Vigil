import Foundation

protocol InputBlockingServiceProtocol: AnyObject {
    var isBlocking: Bool { get }
    var onEventTapDisabled: (() -> Void)? { get set }
    var onUnlockShortcutPressed: (() -> Void)? { get set }
    func startBlocking(mode: LockMode) throws
    func stopBlocking()
    func checkAccessibilityPermission() -> Bool
    func requestAccessibilityPermission()
    func setUnlockShortcut(_ shortcutString: String?)
}

enum InputBlockingError: Error {
    case accessibilityPermissionDenied
    case eventTapCreationFailed
}
