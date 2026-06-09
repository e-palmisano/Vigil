import SwiftUI

struct OverlayContentView: View {
    let style: OverlayStyle
    let isTouchIDAvailable: Bool
    let onUnlock: () -> Void
    var snapshot: NSImage?

    @State private var chromeVisible: Bool = true
    @State private var idleTimer: Timer?
    @AppStorage("showClock") private var showClock: Bool = true
    @AppStorage("showLockMessage") private var showLockMessage: Bool = true
    @AppStorage("autoHideChrome") private var autoHideChrome: Bool = true
    @AppStorage("autoHideDelay") private var autoHideDelay: Double = 5.0
    @AppStorage("respectReducedMotion") private var respectReducedMotion: Bool = true
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var reduceMotion: Bool { systemReduceMotion && respectReducedMotion }

    var body: some View {
        ZStack {
            BackgroundView(style: style, snapshot: snapshot)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                if showLockMessage {
                    LockBadgeView()
                        .opacity(chromeVisible ? 1 : 0)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: chromeVisible)
                }

                if showClock {
                    ClockView()
                }

                Spacer()

                UnlockButton(isTouchIDAvailable: isTouchIDAvailable, onTap: onUnlock)
                    .opacity(chromeVisible ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: chromeVisible)
                    .padding(.bottom, 60)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Vigil lock screen")
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                showChrome()
            case .ended:
                scheduleHide()
            }
        }
        .onAppear {
            scheduleHide()
        }
        .onDisappear {
            idleTimer?.invalidate()
        }
    }

    private func showChrome() {
        idleTimer?.invalidate()
        if !chromeVisible {
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.3)) {
                chromeVisible = true
            }
        }
        scheduleHide()
    }

    private func scheduleHide() {
        idleTimer?.invalidate()
        guard autoHideChrome else { return }
        idleTimer = Timer.scheduledTimer(withTimeInterval: autoHideDelay, repeats: false) { _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5)) {
                chromeVisible = false
            }
        }
    }
}
