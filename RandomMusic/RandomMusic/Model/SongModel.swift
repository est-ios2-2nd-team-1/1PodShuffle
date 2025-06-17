import Foundation

/// 앱 내부 사용 모델입니다.
/// thumbnail의 실제 이미지 데이터가 있음
struct SongModel: Equatable {
    let title: String
    let album: String
    let artist: String
    let genre: Genre
    let id: Int
    let streamUrl: String
    let thumbnailData: Data?

    /// 네트워크로 받아온 SongResponse를 뷰에서 사용할 모델로 생성합니다.
    /// - Parameters:
    ///   - response: SongResponse를 받습니다.
    ///   - thumbnailData: 썸네일 이미지 데이터를 받습니다. 기본값은 nil 입니다.
    init(from response: SongResponse, thumbnailData: Data? = nil) {
        self.title = response.title
        self.album = response.album
        self.artist = response.artist
        self.genre = Genre(rawValue: response.genre)
        self.id = response.id
        self.streamUrl = response.streamUrl
        self.thumbnailData = thumbnailData
    }

    /// 코어데이터 Song 엔티티를 SongModel 객체로 변환합니다.
    /// - Parameter entity: Song Entity를 받습니다.
    init(from entity: Song) {
        self.title = entity.title ?? ""
        self.album = entity.album ?? ""
        self.artist = entity.artist ?? ""
        self.genre = Genre(rawValue: entity.genre ?? "")
        self.id = Int(entity.id)
        self.streamUrl = entity.streamUrl ?? ""
        self.thumbnailData = entity.thumbnailData
    }
}
