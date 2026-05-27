import Foundation

enum BadgePosition: String, Codable, CaseIterable {
    case topRight
    case topLeft
    case bottomRight
    case bottomLeft
    case center

    var displayName: String {
        switch self {
        case .topRight: return "Top Right"
        case .topLeft: return "Top Left"
        case .bottomRight: return "Bottom Right"
        case .bottomLeft: return "Bottom Left"
        case .center: return "Center"
        }
    }
}
