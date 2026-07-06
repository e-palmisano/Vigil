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
        onLockObscured: @escaping () -> Void
    ) {
        unregister()

        // Lock shortcuts fire while unlocked, so a global monitor is the right
        // tool. The unlock and emergency shortcuts must fire while *blocked* —
        // those live in the input tap (see InputBlockingService), not here.
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
