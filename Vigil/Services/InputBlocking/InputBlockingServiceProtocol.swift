import Foundation

protocol InputBlockingServiceProtocol: AnyObject {
    var isBlocking: Bool { get }
    var onEventTapDisabled: (() -> Void)? { get set }
    func startBlocking() throws
    func stopBlocking()
    func checkAccessibilityPermission() -> Bool
    func requestAccessibilityPermission()
}

enum InputBlockingError: Error {
    case accessibilityPermissionDenied
    case eventTapCreationFailed
}
