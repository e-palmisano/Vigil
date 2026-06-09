import AppKit

/// Registers global keyboard shortcuts using NSEvent monitors.
/// Requires Accessibility permission — same entitlement as CGEventTap.
@MainActor
final class GlobalShortcutService {
    private var monitors: [Any] = []
    private var holdTimer: Timer?
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

        // Emergency unlock — 3-second hold required. This monitor only works
        // while the event tap is NOT blocking (monitors never see eaten
        // events); the locked-state path lives in InputBlockingService.
        if let emergency = ParsedShortcut(settings.emergencyShortcut) {
            setupEmergencyHold(parsed: emergency, handler: onEmergencyUnlock)
        }
    }

    private func setupEmergencyHold(parsed: ParsedShortcut, handler: @escaping () -> Void) {
        let down = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Autorepeat would otherwise re-arm a fresh timer every ~80ms,
            // leaking the previous ones.
            guard parsed.matches(event), !event.isARepeat else { return }
            Task { @MainActor [weak self] in self?.startHold(handler) }
        }
        if let down { monitors.append(down) }

        // Cancel hold on any key-up or modifier change
        let up = NSEvent.addGlobalMonitorForEvents(matching: [.keyUp, .flagsChanged]) { [weak self] _ in
            Task { @MainActor [weak self] in self?.cancelHold() }
        }
        if let up { monitors.append(up) }
    }

    private func startHold(_ handler: @escaping () -> Void) {
        cancelHold()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            DispatchQueue.main.async { handler() }
        }
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
    }

    func unregister() {
        cancelHold()
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
