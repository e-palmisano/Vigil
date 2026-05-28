import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider().padding(.vertical, 4)
            lockActionsSection
            Divider().padding(.vertical, 4)
            appActionsSection
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minWidth: 220)
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: appState.menuBarIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(appState.isLocked ? .orange : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text("Vigil")
                    .font(.system(size: 13, weight: .semibold))
                Text(statusDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private var lockActionsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            menuButton(
                title: "Lock Visibly",
                icon: "lock",
                shortcut: "⌘⇧L",
                disabled: appState.isLocked
            ) { appState.lockVisible() }

            menuButton(
                title: "Lock and Obscure",
                icon: "lock.fill",
                shortcut: "⌘⇧K",
                disabled: appState.isLocked
            ) { appState.lockObscured() }

            menuButton(
                title: "Unlock",
                icon: "lock.open",
                shortcut: "⌘⇧U",
                disabled: !appState.isLocked
            ) { appState.unlock() }
        }
    }

    private var appActionsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            menuButton(title: "Settings…", icon: "gear", shortcut: "⌘,", disabled: false) {
                openSettings()
            }
            menuButton(title: "Quit Vigil", icon: "power", shortcut: "⌘Q", disabled: false) {
                NSApp.terminate(nil)
            }
        }
    }

    private func menuButton(
        title: String,
        icon: String,
        shortcut: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 13))
                Spacer()
                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuRowButtonStyle())
        .disabled(disabled)
    }

    private var statusDescription: String {
        switch appState.lockState {
        case .unlocked:           return "Unlocked"
        case .locking:            return "Locking…"
        case .lockedVisible:      return "Locked — visible"
        case .lockedObscured:     return "Locked — obscured"
        case .unlocking:          return "Unlocking…"
        case .error(let msg):     return "Error: \(msg)"
        }
    }
}

private struct MenuRowButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(backgroundColor(pressed: configuration.isPressed))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .onHover { isHovered = $0 }
    }

    private func backgroundColor(pressed: Bool) -> Color {
        if pressed { return Color.accentColor.opacity(0.25) }
        if isHovered { return Color.primary.opacity(0.08) }
        return .clear
    }
}
