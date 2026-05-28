import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("defaultLockMode") var defaultLockMode: String = LockMode.obscured.rawValue
    @AppStorage("overlayStyle") var overlayStyle: String = OverlayStyle.graphiteGradient.rawValue
    @AppStorage("showClock") var showClock: Bool = true
    @AppStorage("showLockMessage") var showLockMessage: Bool = true
    @AppStorage("preventSleep") var preventSleep: Bool = true
    @AppStorage("globalShortcutVisible") var globalShortcutVisible: String = "ctrl+cmd+l"
    @AppStorage("globalShortcutObscured") var globalShortcutObscured: String = "ctrl+shift+cmd+l"
    @AppStorage("emergencyShortcut") var emergencyShortcut: String = "ctrl+opt+cmd+v"
    @AppStorage("globalShortcutUnlock") var globalShortcutUnlock: String = "cmd+shift+l"
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("autoHideChrome") var autoHideChrome: Bool = true
    @AppStorage("autoHideDelay") var autoHideDelay: Double = 5.0
    @AppStorage("respectReducedMotion") var respectReducedMotion: Bool = true
    @AppStorage("badgePosition") var badgePosition: String = BadgePosition.bottomRight.rawValue
    @AppStorage("wasLockedOnExit") var wasLockedOnExit: Bool = false
    @AppStorage("lockModeOnExit") var lockModeOnExit: String = LockMode.obscured.rawValue

    var lockMode: LockMode {
        LockMode(rawValue: defaultLockMode) ?? .obscured
    }

    var currentOverlayStyle: OverlayStyle {
        OverlayStyle(rawValue: overlayStyle) ?? .graphiteGradient
    }

    var currentBadgePosition: BadgePosition {
        BadgePosition(rawValue: badgePosition) ?? .bottomRight
    }
}
