import Foundation

func formattedShortcut(_ raw: String) -> String {
    raw
        .replacingOccurrences(of: "ctrl", with: "⌃")
        .replacingOccurrences(of: "shift", with: "⇧")
        .replacingOccurrences(of: "cmd", with: "⌘")
        .replacingOccurrences(of: "opt", with: "⌥")
        .replacingOccurrences(of: "+", with: "")
        .uppercased()
}
