import Foundation

/// 시간 형식 변환을 담당하는 유틸리티 구조체입니다.
struct TimeFormatter {
    /// 시간을 "MM:SS" 형식의 문자열로 변환합니다.
    /// - Parameter time: 초 단위 시간입니다.
    /// - Returns: 형식화된 시간 문자열입니다.
    static func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
