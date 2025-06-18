import Foundation

/// 서버 응답 모델
/// thumbnail 의 실제 이미지 데이터는 없음
struct SongResponse: Codable {
    let title: String
    let album: String
    let artist: String
    let genre: Genre.RawValue
    let id: Int
    let streamUrl: String
    let thumbnail: ThumbnailResponseType
}
