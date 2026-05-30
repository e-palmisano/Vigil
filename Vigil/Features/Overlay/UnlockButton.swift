import SwiftUI

struct UnlockButton: View {
    let isTouchIDAvailable: Bool
    let onTap: () -> Void

    var body: some View {
        if #available(macOS 26, *) {
            Button(action: onTap) {
                buttonContent
            }
            .buttonStyle(.glass)
            .accessibilityLabel(a11yLabel)
            .focusable()
        } else {
            Button(action: onTap) {
                buttonContent
                    .background(.white.opacity(0.15), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .contentShape(Capsule())
            .accessibilityLabel(a11yLabel)
            .focusable()
        }
    }

    private var buttonContent: some View {
        HStack(spacing: 8) {
            Image(systemName: isTouchIDAvailable ? "touchid" : "key.fill")
                .font(.system(size: 16, weight: .medium))
            Text(isTouchIDAvailable ? "Touch ID or Password" : "Enter Password")
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
    }

    private var a11yLabel: String {
        isTouchIDAvailable ? "Unlock with Touch ID or password" : "Unlock with password"
    }
}
