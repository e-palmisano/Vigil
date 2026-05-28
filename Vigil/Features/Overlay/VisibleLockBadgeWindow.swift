import AppKit
import SwiftUI

final class VisibleLockBadgeWindow: NSPanel {

    private static let badgeSize = CGSize(width: 260, height: 96)
    private static let margin: CGFloat = 16

    init(isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void) {
        let frame = Self.frameForMainScreen()
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
        let badge = VisibleLockBadge(isTouchIDAvailable: isTouchIDAvailable, onUnlock: onUnlock)
        contentView = NSHostingView(rootView: badge)
    }

    private func configure() {
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    private static func frameForMainScreen() -> CGRect {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let origin = CGPoint(
            x: screen.visibleFrame.maxX - badgeSize.width - margin,
            y: screen.visibleFrame.minY + margin
        )
        return CGRect(origin: origin, size: badgeSize)
    }
}
