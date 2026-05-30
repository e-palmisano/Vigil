import SwiftUI
import AppKit

struct ShortcutRecorderView: View {
    let label: String
    @Binding var shortcut: String
    var onCommit: () -> Void = {}

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button(action: toggleRecording) {
                Text(isRecording ? "Type shortcut…" : formattedShortcut(shortcut))
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        isRecording
                            ? Color.accentColor.opacity(0.15)
                            : Color.secondary.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(isRecording ? "Press a key combo, or Escape to cancel" : "Click to record a new shortcut")
        }
        .onDisappear { stopRecording() }
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                stopRecording()
                return nil
            }
            let flags = event.modifierFlags.intersection([.control, .command, .shift, .option])
            guard !flags.isEmpty,
                  let chars = event.charactersIgnoringModifiers,
                  chars.count == 1 else {
                return event
            }
            shortcut = rawShortcut(flags: flags, char: chars.lowercased())
            stopRecording()
            onCommit()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }

    private func rawShortcut(flags: NSEvent.ModifierFlags, char: String) -> String {
        var parts: [String] = []
        if flags.contains(.control) { parts.append("ctrl") }
        if flags.contains(.option)  { parts.append("opt") }
        if flags.contains(.shift)   { parts.append("shift") }
        if flags.contains(.command) { parts.append("cmd") }
        parts.append(char)
        return parts.joined(separator: "+")
    }
}
