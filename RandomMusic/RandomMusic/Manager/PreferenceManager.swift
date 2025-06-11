//
//  PreferenceManager.swift
//  RandomMusic
//
//  Created by drfranken on 6/10/25.
//
import Foundation
import CoreData

class PreferenceManager {
    let context = DataManager.shared.mainContext

    // MARK: - 초기화. 앱 설치 후 최초 실행시 동작함
    func initializePreferences(initialPreferredGenres: [Genre] = []) {
        for genre in Genre.allCases {
            // 기본값 10.0 , songId = 0 은 곡에 상관없는 데이터
            savePreferenceData(genre: genre, songId: 0, score: 10.0, isImmutable: true)

            // 선호장르면 추가 10.0
            if initialPreferredGenres.contains(genre) {
                savePreferenceData(genre: genre, songId: 0, score: 10.0, isImmutable: true)
            }
        }

        saveContext()
    }

    // MARK: - 좋아요/싫어요 누를때 DB에 저장
    func recordAction(genre: Genre, songId: Int, isLike: Bool) {
        let score = isLike ? 2.0 : -1.0
        savePreferenceData(genre: genre, songId:songId, score: score, isImmutable: false)
        saveContext()
    }

    // MARK: - 추천 장르 선택. 다음곡 누를때 장르 가져오는 함수
    func selectRandomGenre() -> Genre {
        var weights: [Genre: Double] = [:]

        for genre in Genre.allCases {
            weights[genre] = calculateScore(for: genre)
        }

        return selectByWeight(weights: weights)
    }

    // MARK: - 곡별 선호도 기록 조회. 곡을 재생할 때 좋아요나 싫어요를 눌렀던 기록이 있는지
    func getUserFeedback(for songId: Int) -> FeedbackType {
        let request: NSFetchRequest<PreferenceData> = PreferenceData.fetchRequest()
        request.predicate = NSPredicate(format: "songId == %lld AND isImmutable == false", Int64(songId))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PreferenceData.insertDate, ascending: false)]
        request.fetchLimit = 1

        guard let latestFeedback = try? context.fetch(request).first else {
            return .none  // 기록 없음
        }

        return latestFeedback.score > 0 ? .like : .dislike
    }


    // MARK: - 피드백 취소 (해당 곡의 좋아요나 싫어요 기록 삭제)
    func cancelFeedback(for songId: Int) -> Bool {
        let request: NSFetchRequest<PreferenceData> = PreferenceData.fetchRequest()
        request.predicate = NSPredicate(format: "songId == %lld AND isImmutable == false", Int64(songId))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PreferenceData.insertDate, ascending: false)]
        request.fetchLimit = 1

        guard let latestFeedback = try? context.fetch(request).first else {
            return false  // 삭제할 기록이 없음
        }

        context.delete(latestFeedback)
        saveContext()
        return true  // 삭제 성공
    }







    // MARK: - Private 함수들
    private func savePreferenceData(genre: Genre, songId: Int, score: Double, isImmutable: Bool) {
        let data = PreferenceData(context: context)
        data.id = UUID()
        data.genre = genre.rawValue
        data.score = score
        data.insertDate = Date()
        data.isImmutable = isImmutable
        data.songId = Int64(songId)
    }

    private func calculateScore(for genre: Genre) -> Double {
        let request: NSFetchRequest<PreferenceData> = PreferenceData.fetchRequest()
        request.predicate = NSPredicate(format: "genre == %@", genre.rawValue)

        guard let allData = try? context.fetch(request) else { return 10.0 }

        var totalScore: Double = 0
        let now = Date()

        for data in allData {
            let daysPassed = Calendar.current.dateComponents([.day],
                from: data.insertDate ?? now, to: now).day ?? 0

            let timeDecay = getTimeDecay(daysPassed: daysPassed)
            totalScore += data.score * timeDecay
        }

        return max(1.0, min(totalScore, 50.0))
    }

    private func getTimeDecay(daysPassed: Int) -> Double {
        switch daysPassed {
        case 0...7: return 1.0
        case 8...14: return 0.8
        case 15...28: return 0.5
        default: return 0.3
        }
    }

    private func selectByWeight(weights: [Genre: Double]) -> Genre {
        let totalWeight = weights.values.reduce(0, +)
        let random = Double.random(in: 0...totalWeight)

        var currentWeight: Double = 0
        for (genre, weight) in weights {
            currentWeight += weight
            if random <= currentWeight {
                return genre
            }
        }

        return .pop // 아무장르도 선택되지 않았을 때의 기본값으로 Pop을 반환. 그런데 이론적으로는 실행될일 없음. 컴파일러가 걱정해서 명시적으로 넣어준 것일 뿐
    }

    private func saveContext() {
        try? context.save()
    }









    // MARK: ------------------ 아래는 디버깅, 테스트용 함수

    // 테스트용 함수
    func runTestScenario() {
        print("🧪 테스트 시작!")

        // 1. 초기화 테스트
        print("\n1️⃣ 초기화 테스트")
//        initializePreferences(initialPreferredGenres: [.jazz, .rock])
        printGenreScores()

        // 2. 좋아요/싫어요 테스트
        print("\n2️⃣ 액션 기록 테스트")
        recordAction(genre: .jazz, songId: 123, isLike: true)
        recordAction(genre: .jazz, songId: 212, isLike: true)
        recordAction(genre: .classic, songId: 789, isLike: false)
        printGenreScores()

        // 3. 피드백 조회 테스트
        print("\n3️⃣ 피드백 조회 테스트")
        print("곡 123: \(getUserFeedback(for: 123))")
        print("곡 212: \(getUserFeedback(for: 212))")
        print("곡 789: \(getUserFeedback(for: 789))")
        print("곡 1: \(getUserFeedback(for: 1))")

        // 4. 추천 테스트
        print("\n4️⃣ 추천 테스트")
        testRecommendations(count: 20)

        // 5. 취소 테스트
        print("\n5️⃣ 취소 테스트")
        print("곡 123 취소 전: \(getUserFeedback(for: 123))")
        let cancelResult = cancelFeedback(for: 123)
        print("취소 결과: \(cancelResult)")
        print("곡 123 취소 후: \(getUserFeedback(for: 123))")

        printGenreScores()

        print("\n✅ 테스트 완료!")
    }




    func printAllData() {
        let request: NSFetchRequest<PreferenceData> = PreferenceData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PreferenceData.insertDate, ascending: false)]

        guard let allData = try? context.fetch(request) else {
            print("데이터 조회 실패")
            return
        }

        print("=== 전체 PreferenceData ===")
        for data in allData {
            print("장르: \(data.genre ?? ""), 점수: \(data.score), 곡ID: \(data.songId), 불변: \(data.isImmutable), 날짜: \(data.insertDate ?? Date())")
        }
    }

    func printGenreScores() {
        print("=== 현재 장르별 점수 ===")
        for genre in Genre.allCases {
            let score = calculateScore(for: genre)
            print("\(genre.rawValue): \(score)")
        }
    }

    func testRecommendations(count: Int = 10) {
        print("=== 추천 테스트 (\(count)회) ===")
        var results: [Genre: Int] = [:]

        for _ in 0..<count {
            let recommended = selectRandomGenre()
            results[recommended, default: 0] += 1
        }

        for (genre, count) in results.sorted(by: { $0.value > $1.value }) {
            print("\(genre.rawValue): \(count)회")
        }
    }

}
