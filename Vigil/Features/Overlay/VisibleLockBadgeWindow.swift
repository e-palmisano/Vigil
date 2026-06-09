import AppKit
import SwiftUI

final class VisibleLockBadgeWindow: NSPanel {

    static let badgeSize = CGSize(width: 260, height: 96)
    static let margin: CGFloat = 16

    init(position: BadgePosition, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame = Self.frame(for: position, in: screen.visibleFrame)
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
        level = .vigilLock
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    /// Badge frame in Cocoa global coordinates (origin bottom-left, y up).
    static func frame(
        for position: BadgePosition,
        in visibleFrame: CGRect,
        size: CGSize = VisibleLockBadgeWindow.badgeSize,
        margin: CGFloat = VisibleLockBadgeWindow.margin
    ) -> CGRect {
        let origin: CGPoint
        switch position {
        case .bottomRight:
            origin = CGPoint(x: visibleFrame.maxX - size.width - margin, y: visibleFrame.minY + margin)
        case .bottomLeft:
            origin = CGPoint(x: visibleFrame.minX + margin, y: visibleFrame.minY + margin)
        case .topRight:
            origin = CGPoint(x: visibleFrame.maxX - size.width - margin, y: visibleFrame.maxY - size.height - margin)
        case .topLeft:
            origin = CGPoint(x: visibleFrame.minX + margin, y: visibleFrame.maxY - size.height - margin)
        case .center:
            origin = CGPoint(x: visibleFrame.midX - size.width / 2, y: visibleFrame.midY - size.height / 2)
        }
        return CGRect(origin: origin, size: size)
    }
}
