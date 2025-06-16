import UIKit

/// 장르
enum Genre: String, CaseIterable, Codable {
    case jazz = "Jazz"
    case pop = "Pop"
    case rock = "Rock"
    case classic = "Classic"
    case rnb = "RnB"
    case hiphop = "Hiphop"

    init(rawValue: String) {
        switch rawValue {
        case "Jazz": self = .jazz
        case "Pop": self = .pop
        case "Rock": self = .rock
        case "Classic": self = .classic
        case "RnB": self = .rnb
        case "Hiphop": self = .hiphop
        default: self = .pop
        }
    }

    var color: UIColor {
        switch self {
        case .classic:
            return .purple
        case .hiphop:
            return .orange
        case .jazz:
            return .green
        case .pop:
            return .systemPink
        case .rnb:
            return .blue
        case .rock:
            return .red
        }
    }
}

