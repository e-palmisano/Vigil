import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Synchronous on purpose: a detached Task may never run before the
        // process exits, which would leave `wasLockedOnExit` stale and
        // auto-lock the next launch after a normal quit.
        AppState.shared.lockManager.emergencyUnlock()
        return .terminateNow
    }
}
