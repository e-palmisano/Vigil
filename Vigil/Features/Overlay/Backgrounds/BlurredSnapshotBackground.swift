import SwiftUI
import AppKit

struct BlurredSnapshotBackground: View {
    // Falls back to dark dimmed if no snapshot is available.
    var snapshot: NSImage?

    var body: some View {
        Group {
            if let image = snapshot {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 32)
                    .overlay(Color.black.opacity(0.35))
            } else {
                DarkDimmedBackground()
            }
        }
        .ignoresSafeArea()
    }
}
