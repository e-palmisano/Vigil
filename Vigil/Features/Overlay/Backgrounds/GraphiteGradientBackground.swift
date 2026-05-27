import SwiftUI

struct GraphiteGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.13, blue: 0.15),
                Color(red: 0.07, green: 0.07, blue: 0.09)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
