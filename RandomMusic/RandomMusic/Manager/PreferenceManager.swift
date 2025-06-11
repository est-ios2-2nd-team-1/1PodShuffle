//
//  PreferenceManager.swift
//  RandomMusic
//
//  Created by drfranken on 6/10/25.
//
import Foundation
import CoreData

/// 선호도 매니저
/// - 선호도 점수 범위 : min 1.0 ~  max 50.0
/// - 좋아요: +2.0 / 싫어요: -1.0
/// - 각 행동마다 preferenceData에 저장이 되고, 저장 시점에 각 장르별 총점을 계산해 preferenceCache 에 저장함.
/// - 장르별 총점이 필요할 경우는 preferenceCache 만 조회해서 사용하면 됨
/// - 오래된 액션은 영향도가 감소(시간감쇠)
///	- 현재~7일전 : 100% 영향도
///	- 7일전~14일전 : 80% 영향도
/// - 14일전~28일전 : 50% 영향도
/// - 28일전~... : 30% 영향도
class PreferenceManager {
    let context = DataManager.shared.mainContext

    /// 초기화. 온보딩에서 선호장르 체크 완료 누를 경우만 동작.
    /// - Parameter initialPreferredGenres: 모든 장르 순회
    /// - Note: 모든 장르가 기본 선호도 10을 가짐. 선택된 선호장르는 10을 더 받음
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

    /// 좋아요/싫어요 누를 때 DB에 저장하는 함수
    /// - Parameters:
    ///   - genre: 곡의 장르
    ///   - songId: 곡 id
    ///   - isLike: 좋아요면 true 싫어요면 false
    func recordAction(genre: Genre, songId: Int, isLike: Bool) {
        let score = isLike ? 2.0 : -1.0
        savePreferenceData(genre: genre, songId:songId, score: score, isImmutable: false)
        saveContext()
    }

    /// 추천 장르 랜덤뽑기
    /// - Returns: 선호도 기반 확률로 장르가 뿅 하고 나옵니다
    func selectRandomGenre() -> Genre {
        var weights: [Genre: Double] = [:]

        print("")
        print("=============")
        print("장르별 현재 점수")
        print("=============")
        for genre in Genre.allCases {
            weights[genre] = calculateScore(for: genre)
        }

        return selectByWeight(weights: weights)
    }

    /// 곡별 선호도 기록 조회. 곡을 재생할 때 좋아요나 싫어요를 눌렀던 기록이 있는지 확인합니다.
    /// - Parameter songId: 곡 id
    /// - Returns: 좋아요, 싫어요, 기록없음
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

    /// 피드백 취소 (해당 곡의 좋아요나 싫어요 기록 삭제)
    /// - Parameter songId: 곡id
    /// - Returns: true 면 성공
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
    /// 선호도 데이터 임시 생성.
    /// - warning: 저장은 따로 해야 함
    private func savePreferenceData(genre: Genre, songId: Int, score: Double, isImmutable: Bool) {
        let data = PreferenceData(context: context)
        data.id = UUID()
        data.genre = genre.rawValue
        data.score = score
        data.insertDate = Date()
        data.isImmutable = isImmutable
        data.songId = Int64(songId)
    }

    /// 각 장르의 선호도 점수 계산
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

        let finalScore = max(1.0, min(totalScore, 50.0))
        print("\(genre.rawValue): \(String(format: "%.2f", finalScore)) (데이터 \(allData.count)개)")

        return finalScore
    }


    /// 시간감쇠 적용
    private func getTimeDecay(daysPassed: Int) -> Double {
        switch daysPassed {
        case 0...7: return 1.0
        case 8...14: return 0.8
        case 15...28: return 0.5
        default: return 0.3
        }
    }

    /// 선호도 기반으로 랜덤장르 추출
    private func selectByWeight(weights: [Genre: Double]) -> Genre {
        let totalWeight = weights.values.reduce(0, +)

        // 각 장르별 선택 확률 로그 출력
        print("=============")
        print("장르별 선택 확률")
        print("=============")
        for (genre, weight) in weights {
            let probability = totalWeight > 0 ? (weight / totalWeight) * 100 : 0
            print("\(genre.rawValue): \(String(format: "%.2f", probability))%")
        }

        let random = Double.random(in: 0...totalWeight)
        print("랜덤값: \(String(format: "%.2f", random)) / \(String(format: "%.2f", totalWeight))")

        var currentWeight: Double = 0
        for (genre, weight) in weights {
            currentWeight += weight
            print("\(genre.rawValue) 누적: \(String(format: "%.2f", currentWeight))")
            if random <= currentWeight {
                print("✅ \(genre.rawValue) 선택됨!")
                return genre
            }
        }

        print("⚠️ 기본값 Pop 선택됨")
        return .pop
    }

    /// 컨텍스트에 실제 저장
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
