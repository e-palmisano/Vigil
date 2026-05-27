import SwiftUI

struct ClockView: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {
            Text(now, format: .dateTime.hour().minute())
                .font(.system(size: 72, weight: .thin, design: .default))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
        }
        .onReceive(timer) { now = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(now, format: .dateTime.hour().minute().weekday().day().month()))
    }
}
