import SwiftUI
import AppKit

struct BackgroundView: View {
    let style: OverlayStyle
    var snapshot: NSImage?

    var body: some View {
        switch style {
        case .darkDimmed:
            DarkDimmedBackground()
        case .blurredSnapshot:
            BlurredSnapshotBackground(snapshot: snapshot)
        case .graphiteGradient:
            GraphiteGradientBackground()
        case .blueGradient:
            BlueGradientBackground()
        case .minimalBlack:
            MinimalBlackBackground()
        }
    }
}
