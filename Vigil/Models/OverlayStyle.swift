import Foundation

enum OverlayStyle: String, Codable, CaseIterable, Identifiable {
    case darkDimmed
    case blurredSnapshot
    case graphiteGradient
    case blueGradient
    case minimalBlack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .darkDimmed: return "Dark Dimmed"
        case .blurredSnapshot: return "Blurred Snapshot"
        case .graphiteGradient: return "Graphite Gradient"
        case .blueGradient: return "Blue Gradient"
        case .minimalBlack: return "Minimal Black"
        }
    }
}
