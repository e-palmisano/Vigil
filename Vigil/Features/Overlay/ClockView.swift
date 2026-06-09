import SwiftUI

struct ClockView: View {
    var body: some View {
        // Only hour/minute are shown, so a per-minute timeline is enough;
        // it also pauses automatically while the view is off-screen.
        TimelineView(.everyMinute) { context in
            VStack(spacing: 4) {
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 72, weight: .thin, design: .default))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(context.date, format: .dateTime.hour().minute().weekday().day().month()))
        }
    }
}
