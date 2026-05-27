import SwiftUI

@main
struct VIGApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.menuBarIcon)
                .symbolRenderingMode(.hierarchical)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(appState.settings)
        }
    }
}
