import Foundation
@testable import Vigil

final class MockDisplayManagerService: DisplayManagerServiceProtocol {
    var hasOverlays: Bool = false
    var createCallCount: Int = 0
    var removeCallCount: Int = 0
    var lastStyle: OverlayStyle?
    var lastMode: LockMode?
    var capturedOnUnlock: (() -> Void)?
    var lastIsTouchIDAvailable: Bool?

    func createOverlayWindows(style: OverlayStyle, mode: LockMode, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void) {
        createCallCount += 1
        lastStyle = style
        lastMode = mode
        lastIsTouchIDAvailable = isTouchIDAvailable
        capturedOnUnlock = onUnlock
        hasOverlays = true
    }

    func removeAllOverlayWindows() {
        removeCallCount += 1
        hasOverlays = false
    }

    func updateStyle(_ style: OverlayStyle) {
        lastStyle = style
    }
}
