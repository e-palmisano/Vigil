import AppKit
import SwiftUI

@MainActor
final class DisplayManagerService: DisplayManagerServiceProtocol {

    private(set) var hasOverlays: Bool = false
    var onInteractiveFramesChanged: (([CGRect]) -> Void)?

    var interactiveFrames: [CGRect] {
        if let badgeWindow { return [badgeWindow.frame] }
        return overlayWindows.map { $0.frame }
    }

    private var badgeWindow: VisibleLockBadgeWindow?
    private var overlayWindows: [OverlayWindow] = []
    private var currentStyle: OverlayStyle = .darkDimmed
    private var currentMode: LockMode = .obscured
    private var currentBadgePosition: BadgePosition = .bottomRight
    private var isTouchIDAvailable: Bool = false
    private var isAuthenticationModeActive: Bool = false
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
        notifyInteractiveFramesChanged()
    }

    func removeAllOverlayWindows() {
        stopObservingScreenChanges()
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        onUnlockCallback = nil
        hasOverlays = false
        isAuthenticationModeActive = false
        removeBadgeWindow()
        notifyInteractiveFramesChanged()
    }

    func createBadgeWindow(position: BadgePosition, isTouchIDAvailable: Bool, onUnlock: @escaping () -> Void) {
        removeBadgeWindow()
        currentBadgePosition = position
        self.isTouchIDAvailable = isTouchIDAvailable
        onUnlockCallback = onUnlock
        let window = VisibleLockBadgeWindow(position: position, isTouchIDAvailable: isTouchIDAvailable, onUnlock: onUnlock)
        window.level = currentWindowLevel
        window.makeKeyAndOrderFront(nil)
        badgeWindow = window
        observeScreenChanges()
        notifyInteractiveFramesChanged()
    }

    func removeBadgeWindow() {
        badgeWindow?.orderOut(nil)
        badgeWindow = nil
        if !hasOverlays { stopObservingScreenChanges() }
    }

    func setAuthenticationMode(_ active: Bool) {
        isAuthenticationModeActive = active
        let level = currentWindowLevel
        overlayWindows.forEach { $0.level = level }
        badgeWindow?.level = level
    }

    private func notifyInteractiveFramesChanged() {
        onInteractiveFramesChanged?(interactiveFrames)
    }

    func updateStyle(_ style: OverlayStyle) {
        guard style != currentStyle else { return }
        currentStyle = style
        guard hasOverlays else { return }
        overlayWindows.forEach { window in
            window.setContent(overlayContent(for: style))
        }
    }

    // MARK: - Private

    /// `.floating` sits above normal app windows but below the system
    /// authentication panel; the lock level covers everything.
    private var currentWindowLevel: NSWindow.Level {
        isAuthenticationModeActive ? .floating : .vigilLock
    }

    private func buildWindows() {
        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            window.level = currentWindowLevel
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
        guard screenChangeObserver == nil else { return }
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
        if hasOverlays {
            let callback = onUnlockCallback ?? {}
            let style = currentStyle
            let mode = currentMode
            let touchID = isTouchIDAvailable
            let authActive = isAuthenticationModeActive
            removeAllOverlayWindows()
            createOverlayWindows(style: style, mode: mode, isTouchIDAvailable: touchID, onUnlock: callback)
            // A rebuild mid-authentication must not cover the system prompt.
            if authActive { setAuthenticationMode(true) }
        } else if badgeWindow != nil {
            // Visible mode: reposition the badge on the (possibly new) main
            // screen so it doesn't strand on stale coordinates after hot-plug.
            let callback = onUnlockCallback ?? {}
            createBadgeWindow(position: currentBadgePosition, isTouchIDAvailable: isTouchIDAvailable, onUnlock: callback)
        }
    }
}
