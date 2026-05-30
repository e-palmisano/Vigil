import SwiftUI

struct LockBadgeView: View {
    var body: some View {
        if #available(macOS 26, *) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
                .padding(24)
                .glassEffect(in: Circle())
                .accessibilityLabel("Screen locked")
                .accessibilityHidden(false)
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityLabel("Screen locked")
                .accessibilityHidden(false)
        }
    }
}
