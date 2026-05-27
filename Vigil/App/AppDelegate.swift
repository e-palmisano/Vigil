import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task { @MainActor in
            AppState.shared.lockManager.emergencyUnlock()
        }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            AppState.shared.lockManager.emergencyUnlock()
        }
    }
}
