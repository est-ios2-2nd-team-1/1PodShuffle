import Foundation

enum Genre: String, CaseIterable, Codable {
    case jazz = "Jazz"
    case pop = "Pop"
    case rock = "Rock"
    case classic = "Classic"
    case rnb = "RnB"
    case hiphop = "Hiphop"
    case unknown = "Unknown"

    init(rawValue: String) {
        switch rawValue {
        case "Jazz": self = .jazz
        case "Pop": self = .pop
        case "Rock": self = .rock
        case "Classic": self = .classic
        case "RnB": self = .rnb
        case "Hiphop": self = .hiphop
        default: self = .unknown
        }
    }
}

enum FeedbackType {
    case like      // 좋아요
    case dislike   // 싫어요
    case none      // 기록 없음
}
