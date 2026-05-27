import Foundation

protocol DisplayManagerServiceProtocol: AnyObject {
    var hasOverlays: Bool { get }
    func createOverlayWindows(style: OverlayStyle, mode: LockMode, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void)
    func removeAllOverlayWindows()
    func updateStyle(_ style: OverlayStyle)
}
