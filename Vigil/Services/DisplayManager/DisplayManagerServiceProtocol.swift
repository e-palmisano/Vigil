import Foundation
import CoreGraphics

protocol DisplayManagerServiceProtocol: AnyObject {
    var hasOverlays: Bool { get }

    /// Frames (Cocoa global coordinates) of Vigil's currently-shown windows —
    /// the badge in visible mode, or the overlays in obscured mode. These are
    /// the only regions where clicks should reach Vigil.
    var interactiveFrames: [CGRect] { get }

    /// Fired whenever the set of windows changes (build / teardown / screen
    /// hot-plug) so consumers can refresh the interactive regions.
    var onInteractiveFramesChanged: (([CGRect]) -> Void)? { get set }

    func createOverlayWindows(style: OverlayStyle, mode: LockMode, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void)
    func removeAllOverlayWindows()
    func updateStyle(_ style: OverlayStyle)
    func createBadgeWindow(position: BadgePosition, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void)
    func removeBadgeWindow()

    /// While the system authentication prompt is up, Vigil's windows are
    /// dropped below it (instead of being torn down) so the screen stays
    /// covered and clicks outside the prompt keep being swallowed.
    func setAuthenticationMode(_ active: Bool)
}
