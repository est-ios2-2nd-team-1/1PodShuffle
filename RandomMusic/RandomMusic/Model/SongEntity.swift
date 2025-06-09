import Foundation

struct SongEntity {
    let title: String
    let album: String
    let artist: String
    let genre: String
    let id: Int
    let streamUrl: String
    let thumbnailPath: String? // 파일 경로

    init(from song: SongModel, thumbnailPath: String? = nil) {
        self.title = song.title
        self.album = song.album
        self.artist = song.artist
        self.genre = song.genre
        self.id = song.id
        self.streamUrl = song.streamUrl
        self.thumbnailPath = thumbnailPath
    }
}

