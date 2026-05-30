import Foundation
import CoreGraphics
@testable import Vigil

final class MockDisplayManagerService: DisplayManagerServiceProtocol {
    var hasOverlays: Bool = false
    var hasBadgeWindow: Bool = false
    var createCallCount: Int = 0
    var removeCallCount: Int = 0
    var createBadgeCallCount: Int = 0
    var removeBadgeCallCount: Int = 0
    var lastStyle: OverlayStyle?
    var lastMode: LockMode?
    var capturedOnUnlock: (() -> Void)?
    var lastIsTouchIDAvailable: Bool?
    var capturedBadgeOnUnlock: (() -> Void)?

    var onInteractiveFramesChanged: (([CGRect]) -> Void)?
    /// Frames the mock reports when windows are "shown".
    var stubbedInteractiveFrames: [CGRect] = []

    var interactiveFrames: [CGRect] {
        hasBadgeWindow || hasOverlays ? stubbedInteractiveFrames : []
    }

    func createOverlayWindows(style: OverlayStyle, mode: LockMode, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void) {
        createCallCount += 1
        lastStyle = style
        lastMode = mode
        lastIsTouchIDAvailable = isTouchIDAvailable
        capturedOnUnlock = onUnlock
        hasOverlays = true
        onInteractiveFramesChanged?(interactiveFrames)
    }

    func removeAllOverlayWindows() {
        removeCallCount += 1
        hasOverlays = false
        hasBadgeWindow = false
        onInteractiveFramesChanged?(interactiveFrames)
    }

    func updateStyle(_ style: OverlayStyle) {
        lastStyle = style
    }

    func createBadgeWindow(isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void) {
        createBadgeCallCount += 1
        lastIsTouchIDAvailable = isTouchIDAvailable
        capturedBadgeOnUnlock = onUnlock
        hasBadgeWindow = true
        onInteractiveFramesChanged?(interactiveFrames)
    }

    func removeBadgeWindow() {
        removeBadgeCallCount += 1
        hasBadgeWindow = false
    }
}
