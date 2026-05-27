import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vigil")
                .font(.headline)
                .padding(.bottom, 4)

            Divider()

            Button("Lock Visibly") { appState.lockVisible() }
                .disabled(appState.isLocked)
            Button("Lock and Obscure") { appState.lockObscured() }
                .disabled(appState.isLocked)
            Button("Unlock") { appState.unlock() }
                .disabled(!appState.isLocked)

            Divider()

            Button("Settings…") { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }
            Button("Quit Vigil") { NSApp.terminate(nil) }
        }
        .padding(8)
    }
}
