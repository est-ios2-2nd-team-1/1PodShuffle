import UIKit

/// 장르를 표현하는 타입입니다.
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

    var image: UIImage? {
        switch self {
        case .jazz:
            return UIImage(named: "homeJazz")
        case .pop:
            return UIImage(named: "homePop")
        case .rock:
            return UIImage(named: "homeRock")
        case .classic:
            return UIImage(named: "homeClassic")
        case .rnb:
            return UIImage(named: "homeRnB")
        case .hiphop:
            return UIImage(named: "homeHiphop")
        }
    }
}

