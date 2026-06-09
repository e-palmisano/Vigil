import AppKit
import SwiftUI

extension NSWindow.Level {
    /// One step above the screen saver level — covers everything, including
    /// full-screen apps and the Dock.
    static let vigilLock = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
}

final class OverlayWindow: NSPanel {

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    private let targetScreen: NSScreen

    init(screen: NSScreen) {
        self.targetScreen = screen
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    private func configure() {
        level = .vigilLock
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        isOpaque = true
        hasShadow = false
        backgroundColor = .black
    }

    func setContent<V: View>(_ view: V) {
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(origin: .zero, size: targetScreen.frame.size)
        hosting.autoresizingMask = [.width, .height]

        let blocker = MouseBlockingView()
        blocker.frame = CGRect(origin: .zero, size: targetScreen.frame.size)
        blocker.autoresizingMask = [.width, .height]
        blocker.addSubview(hosting)

        contentView = blocker
    }
}
