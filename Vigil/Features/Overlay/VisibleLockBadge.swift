import SwiftUI

struct VisibleLockBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible: Bool = true

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .medium))
                Text("Vigil Active")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .opacity(visible ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: visible)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(16)
        .accessibilityLabel("Vigil input lock active")
        .onAppear {
            scheduleAutoHide()
        }
    }

    private func scheduleAutoHide() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.4)) {
                visible = false
            }
        }
    }
}
