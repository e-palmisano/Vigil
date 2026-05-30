import Foundation

enum LockState: Equatable {
    case unlocked
    case locking
    case lockedVisible
    case lockedObscured
    case unlocking
    case error(String)

    static func == (lhs: LockState, rhs: LockState) -> Bool {
        switch (lhs, rhs) {
        case (.unlocked, .unlocked): return true
        case (.locking, .locking): return true
        case (.lockedVisible, .lockedVisible): return true
        case (.lockedObscured, .lockedObscured): return true
        case (.unlocking, .unlocking): return true
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }

    var isLocked: Bool {
        switch self {
        case .lockedVisible, .lockedObscured: return true
        default: return false
        }
    }

    var localizedDescription: String {
        switch self {
        case .unlocked:       return "Unlocked"
        case .locking:        return "Locking…"
        case .lockedVisible:  return "Locked — visible"
        case .lockedObscured: return "Locked — obscured"
        case .unlocking:      return "Unlocking…"
        case .error(let code):
            switch code {
            case "eventTapDisabled":      return "Input monitoring stopped"
            case "eventTapCreationFailed": return "Could not start input blocking"
            default:                      return "Error"
            }
        }
    }
}
