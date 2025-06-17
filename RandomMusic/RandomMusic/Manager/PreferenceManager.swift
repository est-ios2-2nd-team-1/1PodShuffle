import CoreData
import Foundation

/// 선호도 매니저
/// - 선호도 점수 범위 : min 1.0 ~  max 50.0
/// - 좋아요: +2.0 / 싫어요: -1.0
/// - 각 행동마다 preferenceData에 저장이 되고, 저장 시점에 각 장르별 총점을 계산해 preferenceCache 에 저장함.
/// - 장르별 총점이 필요할 경우는 preferenceCache 만 조회해서 사용하면 됨
/// - 오래된 액션은 영향도가 감소(시간감쇠)
///    - 현재~7일전 : 100% 영향도
///    - 7일전~14일전 : 80% 영향도
/// - 14일전~28일전 : 50% 영향도
/// - 28일전~... : 30% 영향도
class PreferenceManager {
    let context = DataManager.shared.mainContext

    /// 초기 선호 장르 설정하는 함수
    /// - parameter initialPreferredGenres: 사용자 선택한 장르 배열. 선택 안하면 기본값만 들어감
    /// - note: 전체 장르에 기본값 10 넣고, 선택된 장르는 +10 더 넣음
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

    /// 모든 선호도 기록 초기화함
    /// - note: 디버깅이나 테스트할 때 전체 삭제하고 다시 시작할 때 사용
    func resetAllPreferences() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = PreferenceData.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(batchDeleteRequest)
            print("모든 선호도 데이터 삭제완료")
            saveContext()
        } catch {
            print("선호도 데이터 초기화 실패: \(error)")
        }
    }


    /// 좋아요/싫어요 누른 결과 저장하는 함수
    /// - parameter genre: 곡 장르
    /// - parameter songId: 곡 ID
    /// - parameter isLike: true면 좋아요, false면 싫어요
    func recordAction(genre: Genre, songId: Int, isLike: Bool) {
        let score = isLike ? 2.0 : -1.0
        savePreferenceData(genre: genre, songId:songId, score: score, isImmutable: false)
        saveContext()
    }

    /// 선호도 점수 기반으로 장르 하나 랜덤 선택함
    /// - returns: 확률 기반으로 뽑힌 장르
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

    /// 해당 곡에 대한 유저 피드백 조회
    /// - parameter songId: 곡 ID
    /// - returns: .like / .dislike / .none 중 하나
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

    /// 좋아요나 싫어요 눌렀던 거 취소하는 함수
    /// - parameter songId: 곡 ID
    /// - returns: 삭제 성공하면 true
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

    /// 현재 장르별 추천 확률 리턴
    /// - returns: 각 장르별 점수 비율을 소수점 두 자리까지 포함한 딕셔너리
    func getGenrePercentage() -> [Genre: Double] {
        var weights: [Genre: Double] = [:]

        for genre in Genre.allCases {
            weights[genre] = calculateScore(for: genre)
        }

        let totalWeight = weights.values.reduce(0, +)

        var percentages: [Genre: Double] = [:]
        for (genre, weight) in weights {
            let percentage = totalWeight > 0 ? (weight / totalWeight) * 100 : 0
            percentages[genre] = Double(String(format: "%.2f", percentage)) ?? percentage // 반올림해서 소숫점 2번째 자리까지 표시
        }

        return percentages
    }
}

private extension PreferenceManager {
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

        for (genre, weight) in weights {
            let probability = totalWeight > 0 ? (weight / totalWeight) * 100 : 0
        }

        let random = Double.random(in: 0...totalWeight)
        var currentWeight: Double = 0

        for (genre, weight) in weights {
            currentWeight += weight
            if random <= currentWeight {
                return genre
            }
        }

        return .pop
    }

    /// 컨텍스트에 실제 저장
    private func saveContext() {
        try? context.save()
    }
}
