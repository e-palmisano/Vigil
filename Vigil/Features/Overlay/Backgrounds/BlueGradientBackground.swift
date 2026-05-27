import SwiftUI

struct BlueGradientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.10, blue: 0.30),
                Color(red: 0.10, green: 0.18, blue: 0.45),
                Color(red: 0.04, green: 0.08, blue: 0.22)
            ],
            startPoint: animating && !reduceMotion ? .topLeading : .bottomTrailing,
            endPoint: animating && !reduceMotion ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}
