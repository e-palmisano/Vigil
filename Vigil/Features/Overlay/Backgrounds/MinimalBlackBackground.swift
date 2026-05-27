import SwiftUI

struct MinimalBlackBackground: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            // Subtle noise texture via Canvas
            Canvas { context, size in
                for _ in 0..<Int(size.width * size.height / 400) {
                    let x = Double.random(in: 0..<size.width)
                    let y = Double.random(in: 0..<size.height)
                    let opacity = Double.random(in: 0.01...0.04)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
            .ignoresSafeArea()
            .drawingGroup()
        }
    }
}
