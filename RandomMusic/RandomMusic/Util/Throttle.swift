import Foundation

/// Throttle을 사용하기 위한 객체입니다.
final class Throttle {
    private var isBlocking: Bool = false

    /// Throttle을 적용합니다.
    /// - Parameters:
    ///   - block: 적용할 실행 구문을 작성합니다.
    ///   - seconds: 소수점 형태로 몇 초간 Throttle 할 건지 입력합니다. (기본 값 0.3)
    func run(seconds: Double = 0.3, _ block: @escaping () -> Void) {
        guard !isBlocking else { return }
        isBlocking = true
        block()

        Task {
            try await Task.sleep(for: .seconds(seconds))
            isBlocking = false
        }
    }
}
