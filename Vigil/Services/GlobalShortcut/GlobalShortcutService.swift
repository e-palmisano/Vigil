import AppKit

/// Registers global keyboard shortcuts using NSEvent monitors.
/// Requires Accessibility permission — same entitlement as CGEventTap.
@MainActor
final class GlobalShortcutService {
    private var monitors: [Any] = []
    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    func register(
        onLockVisible: @escaping () -> Void,
        onLockObscured: @escaping () -> Void,
        onEmergencyUnlock: @escaping () -> Void
    ) {
        unregister()

        // Regular shortcuts — instant
        let shortcuts: [(String, () -> Void)] = [
            (settings.globalShortcutVisible, onLockVisible),
            (settings.globalShortcutObscured, onLockObscured)
        ]
        for (shortcutString, handler) in shortcuts {
            guard let parsed = ParsedShortcut(shortcutString) else { continue }
            let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                if parsed.matches(event) {
                    DispatchQueue.main.async { handler() }
                }
            }
            if let monitor { monitors.append(monitor) }
        }

        // Emergency unlock — 3-second hold required
        if let emergency = ParsedShortcut(settings.emergencyShortcut) {
            setupEmergencyHold(parsed: emergency, handler: onEmergencyUnlock)
        }
    }

    private func setupEmergencyHold(parsed: ParsedShortcut, handler: @escaping () -> Void) {
        var holdTimer: Timer?

        let down = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if parsed.matches(event) {
                holdTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    DispatchQueue.main.async { handler() }
                }
            }
        }
        if let down { monitors.append(down) }

        // Cancel hold on any key-up or modifier change
        let up = NSEvent.addGlobalMonitorForEvents(matching: [.keyUp, .flagsChanged]) { _ in
            holdTimer?.invalidate()
            holdTimer = nil
        }
        if let up { monitors.append(up) }
    }

    func unregister() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
    }
}

// MARK: - ParsedShortcut

/// Parses shortcut strings like "ctrl+cmd+l" into flags + key character.
struct ParsedShortcut {
    let modifiers: NSEvent.ModifierFlags
    let character: String

    init?(_ raw: String) {
        let parts = raw.lowercased().components(separatedBy: "+")
        guard let keyChar = parts.last, keyChar.count == 1 else { return nil }
        character = keyChar

        var flags: NSEvent.ModifierFlags = []
        for part in parts.dropLast() {
            switch part {
            case "ctrl":  flags.insert(.control)
            case "cmd":   flags.insert(.command)
            case "shift": flags.insert(.shift)
            case "opt":   flags.insert(.option)
            default: break
            }
        }
        guard !flags.isEmpty else { return nil }
        modifiers = flags
    }

    func matches(_ event: NSEvent) -> Bool {
        let eventFlags = event.modifierFlags.intersection([.control, .command, .shift, .option])
        return eventFlags == modifiers &&
               event.charactersIgnoringModifiers?.lowercased() == character
    }
}
