import AppKit
import SwiftUI

@MainActor
final class DisplayManagerService: DisplayManagerServiceProtocol {

    private(set) var hasOverlays: Bool = false

    private var overlayWindows: [OverlayWindow] = []
    private var currentStyle: OverlayStyle = .darkDimmed
    private var currentMode: LockMode = .obscured
    private var isTouchIDAvailable: Bool = false
    private var onUnlockCallback: (() -> Void)?
    private var screenChangeObserver: NSObjectProtocol?

    func createOverlayWindows(style: OverlayStyle, mode: LockMode, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void) {
        removeAllOverlayWindows()
        currentStyle = style
        currentMode = mode
        self.isTouchIDAvailable = isTouchIDAvailable
        onUnlockCallback = onUnlock

        buildWindows()
        observeScreenChanges()
        hasOverlays = true
    }

    func removeAllOverlayWindows() {
        stopObservingScreenChanges()
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        onUnlockCallback = nil
        hasOverlays = false
    }

    func updateStyle(_ style: OverlayStyle) {
        currentStyle = style
        guard hasOverlays else { return }
        overlayWindows.forEach { window in
            window.setContent(overlayContent(for: style))
        }
    }

    // MARK: - Private

    private func buildWindows() {
        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            window.setContent(overlayContent(for: currentStyle))
            window.makeKeyAndOrderFront(nil)
            overlayWindows.append(window)
        }
    }

    private func overlayContent(for style: OverlayStyle) -> some View {
        OverlayContentView(
            style: style,
            isTouchIDAvailable: isTouchIDAvailable,
            onUnlock: onUnlockCallback ?? {}
        )
    }

    private func observeScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handleScreenChange() }
        }
    }

    private func stopObservingScreenChanges() {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            screenChangeObserver = nil
        }
    }

    private func handleScreenChange() {
        guard hasOverlays else { return }
        let callback = onUnlockCallback ?? {}
        let style = currentStyle
        let mode = currentMode
        let touchID = isTouchIDAvailable
        removeAllOverlayWindows()
        createOverlayWindows(style: style, mode: mode, isTouchIDAvailable: touchID, onUnlock: callback)
    }
}
