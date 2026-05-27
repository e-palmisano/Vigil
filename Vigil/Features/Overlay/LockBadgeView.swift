import SwiftUI

struct LockBadgeView: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 48, weight: .light))
            .foregroundStyle(.white.opacity(0.85))
            .accessibilityLabel("Screen locked")
            .accessibilityHidden(false)
    }
}
