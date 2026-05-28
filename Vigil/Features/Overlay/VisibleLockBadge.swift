import SwiftUI

struct VisibleLockBadge: View {
    let isTouchIDAvailable: Bool
    let onUnlock: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Vigil Active")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                if isTouchIDAvailable {
                    Image(systemName: "touchid")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Button(action: onUnlock) {
                Label("Unlock", systemImage: "lock.open.fill")
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .frame(width: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityLabel("Vigil input lock active. Press Unlock to disable.")
    }
}
