import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            OverlaySettingsView()
                .tabItem { Label("Overlay", systemImage: "rectangle.on.rectangle") }
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .environmentObject(settings)
        .frame(minWidth: 480, minHeight: 400)
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        settings.launchAtLogin = newValue
                        applyLaunchAtLogin(newValue)
                    }
                ))

                Toggle("Prevent Sleep While Locked", isOn: $settings.preventSleep)

                Picker("Default Lock Mode", selection: $settings.defaultLockMode) {
                    Text("Visible — screen stays visible").tag(LockMode.visible.rawValue)
                    Text("Obscured — covers all displays").tag(LockMode.obscured.rawValue)
                }
            }

            Section("Visible Lock") {
                Picker("Badge Position", selection: $settings.badgePosition) {
                    Text("Bottom Right").tag(BadgePosition.bottomRight.rawValue)
                    Text("Bottom Left").tag(BadgePosition.bottomLeft.rawValue)
                    Text("Top Right").tag(BadgePosition.topRight.rawValue)
                    Text("Top Left").tag(BadgePosition.topLeft.rawValue)
                }
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // SMAppService errors are non-fatal — setting persists for next attempt
            }
        }
    }
}

// MARK: - Overlay

private struct OverlaySettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Background") {
                Picker("Style", selection: $settings.overlayStyle) {
                    Text("Dark Dimmed").tag(OverlayStyle.darkDimmed.rawValue)
                    Text("Blurred Snapshot").tag(OverlayStyle.blurredSnapshot.rawValue)
                    Text("Graphite Gradient").tag(OverlayStyle.graphiteGradient.rawValue)
                    Text("Blue Gradient").tag(OverlayStyle.blueGradient.rawValue)
                    Text("Minimal Black").tag(OverlayStyle.minimalBlack.rawValue)
                }
                .pickerStyle(.radioGroup)

                overlayPreview
            }

            Section("Chrome") {
                Toggle("Show Clock", isOn: $settings.showClock)
                Toggle("Show Lock Message", isOn: $settings.showLockMessage)
                Toggle("Auto-Hide Controls", isOn: $settings.autoHideChrome)

                if settings.autoHideChrome {
                    HStack {
                        Text("Hide After")
                        Slider(value: $settings.autoHideDelay, in: 2...15, step: 1)
                        Text("\(Int(settings.autoHideDelay))s")
                            .monospacedDigit()
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }

            Section("Accessibility") {
                Toggle("Respect Reduced Motion", isOn: $settings.respectReducedMotion)
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var overlayPreview: some View {
        let style = OverlayStyle(rawValue: settings.overlayStyle) ?? .graphiteGradient
        return ZStack {
            BackgroundView(style: style, snapshot: nil)
            VStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Preview")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 1))
    }
}

// MARK: - Shortcuts

private struct ShortcutsSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Lock Shortcuts") {
                shortcutRow(label: "Lock Visibly", value: settings.globalShortcutVisible)
                shortcutRow(label: "Lock and Obscure", value: settings.globalShortcutObscured)
            }

            Section("Emergency") {
                shortcutRow(label: "Emergency Unlock", value: settings.emergencyShortcut)
                Text("Emergency unlock bypasses authentication. Use it only if the normal unlock fails.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private func shortcutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(formattedShortcut(value))
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
        }
    }

}
