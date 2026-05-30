import AppKit
import SwiftUI

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
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
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

    func updateForScreen() {
        setFrame(targetScreen.frame, display: false)
    }
}
