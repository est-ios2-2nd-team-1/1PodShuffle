/// 곡정보 api 응답받을 때 thumbanil 항목의 값
enum ThumbnailResponseType: Int, CaseIterable, Codable {
    case exists = 1
    case pending = 0
    case none = -1

    var description: String {
        switch self {
        case .exists:
            return "썸네일 존재"
        case .pending:
            return "썸네일 생성 대기중"
        case .none:
            return "썸네일 없는 곡"
        }
    }
}
