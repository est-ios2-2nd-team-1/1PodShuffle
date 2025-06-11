//
//  Genre.swift
//  RandomMusic
//
//  Created by drfranken on 6/9/25.
//

enum Genre: String, CaseIterable {
    case jazz = "Jazz"
    case pop = "Pop"
    case rock = "Rock"
    case classic = "Classic"
    case rnb = "RnB"
    case hiphop = "Hiphop"
}


enum FeedbackType {
    case like      // 좋아요
    case dislike   // 싫어요
    case none      // 기록 없음
}
