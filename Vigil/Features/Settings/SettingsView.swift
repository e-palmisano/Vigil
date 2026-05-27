import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            OverlaySettingsView()
                .tabItem { Label("Overlay", systemImage: "rectangle.on.rectangle") }
        }
        .environmentObject(settings)
        .frame(minWidth: 480, minHeight: 360)
    }
}

private struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Prevent Sleep While Locked", isOn: $settings.preventSleep)
            Picker("Default Lock Mode", selection: $settings.defaultLockMode) {
                Text("Visible").tag(LockMode.visible.rawValue)
                Text("Obscured").tag(LockMode.obscured.rawValue)
            }
        }
        .padding(24)
    }
}

private struct OverlaySettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Picker("Background Style", selection: $settings.overlayStyle) {
                Text("Dark Dimmed").tag(OverlayStyle.darkDimmed.rawValue)
                Text("Blurred Snapshot").tag(OverlayStyle.blurredSnapshot.rawValue)
                Text("Graphite Gradient").tag(OverlayStyle.graphiteGradient.rawValue)
                Text("Blue Gradient").tag(OverlayStyle.blueGradient.rawValue)
                Text("Minimal Black").tag(OverlayStyle.minimalBlack.rawValue)
            }
            Toggle("Show Clock", isOn: $settings.showClock)
            Toggle("Auto-Hide Controls", isOn: $settings.autoHideChrome)
        }
        .padding(24)
    }
}
