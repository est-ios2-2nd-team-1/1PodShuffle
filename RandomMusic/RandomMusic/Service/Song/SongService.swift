import AVFoundation

/// Song 관련 비지니스 로직
class SongService {

    // 상수들
    private let LOAD_SONGS_COUNT = 10
    private let M3U8_FILE_NAME = "output.m3u8"
    private let THUMBNAIL_FILE_NAME = "cover.jpg"

    // 참조 객체 생성
    private let networkService = NetworkService()

    /// 장르별 랜덤곡을 요청
    /// - Warning: 파라미터를 넣지 않으면 선호도에 기반해서 자동으로 랜덤장르를 요청함. 특수한 상황이 아니라면 파라미터 넣지 말고 쓰세요
    /// - Parameter genre: 장르.
    /// - Returns: 바로 쓸 수 있는 SongModel. 썸네일 Data 와 곡정보가 모두 들어있다.
    func getMusic(genre: Genre? = nil) async throws -> SongModel {
        var realGenre: Genre // 장르가 없으면 장르를 랜덤으로 뽑아서 넣어주기 위해서 새로 선언

        if let genre { // 장르 입력값이 있으면 그대로 사용
            realGenre = genre
        } else { // 장르 입력값이 없으면 선호도 기반으로 랜덤으로 추출
            let pm = PreferenceManager()
            realGenre = pm.selectRandomGenre()
        }

        // 음악 정보 호출
        let response: SongResponse = try await fetchRandomMusic(genre: realGenre)

        // 썸네일 호출
        var thumbnailData: Data? = nil

        if response.thumbnail == .exists {
            do {
                thumbnailData = try await fetchThumbnailImage(from: response.streamUrl)
            } catch {
                print("썸네일 로드 실패: \(error)") // 썸네일 실패해도 음악은 재생 가능
            }
        }

        // 썸네일이 들어간 모델로 만들기
        let songModel = SongModel(from: response, thumbnailData: thumbnailData)

        return songModel
    }

    /// 장르별로 10곡을 가져오는 메소드입니다.
    /// - Parameter genre: 선택된 장르를 받습니다.
    /// - Returns: 해당 장르의 10곡을 반환합니다.
    func getMusics(genre: Genre? = nil) async throws -> [SongModel] {
        var realGenre: Genre

        if let genre {
            realGenre = genre
        } else {
            let pm = PreferenceManager()
            realGenre = pm.selectRandomGenre()
        }

        let responseList = try await fetchRandomMusics(genre: realGenre)
        var songModelList: [SongModel] = []
        for	response in responseList {
            var thumbnailData: Data? = nil

            if response.thumbnail == .exists {
                do {
                    thumbnailData = try await fetchThumbnailImage(from: response.streamUrl)
                } catch {
                    print("썸네일 로드 실패: \(error)")
                }
            }

            songModelList.append(SongModel(from: response, thumbnailData: thumbnailData))
        }

        return songModelList
    }

    /// API 요청 시 필요한 인증 헤더 등을 포함한 AVURLAsset을 생성하여,
    /// 보안이 필요한 스트리밍 URL에도 접근 가능하도록 하는 메서드
    /// - Parameter url: API의 상대 경로. 예: `"/api/music/stream/123"`
    /// - Returns: 생성된 `AVURLAsset` 객체. 실패 시 nil이 아닌 예외를 throw
    /// - Throws: 네트워크 요청 생성에 실패하거나 URL이 잘못된 경우 오류를 throw
    /// - Note: 반환되는 AVURLAsset은 헤더가 필요한 m3u8 스트리밍 등에서 사용됨
    func createAssetWithHeaders(url: String) throws -> AVURLAsset? {
        let request = try networkService.makeRequest(endpoint: url)
        let headers = request.allHTTPHeaderFields ?? [:]
        let asset = AVURLAsset(url: request.url!, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])

        return asset
    }

}

private extension SongService {
    /// 장르에 기반한 곡 메타정보(SongResponse)를 가져온다
    /// - Parameter genre: 장르. enum
    /// - Returns: api 응답형식. SongModel 로 변환 후 사용해야함
    private func fetchRandomMusic(genre: Genre? = nil) async throws -> SongResponse {
        var endpoint = "/api/music/random"
        if let genre = genre {
            endpoint += "?genre=\(genre.rawValue)"
        }

        return try await networkService.fetch(endpoint: endpoint)
    }

    /// 장르에 기반한 곡 메타정보 가져오기 (여러곡)
    /// - Parameter genre: 장르. enum
    /// - Returns: api 응답형식. SongModel 로 변환 후 사용해야함
    private func fetchRandomMusics(genre: Genre? = nil) async throws -> [SongResponse] {
        var endpoint = "/api/music/randomMany/\(LOAD_SONGS_COUNT)"
        if let genre = genre {
            endpoint += "?genre=\(genre.rawValue)"
        }

        return try await networkService.fetch(endpoint: endpoint)
    }

    /// 곡ID 기반으로 곡정보 호출. 현재 사용안함. 고도화 용
    /// - Parameter id: 곡 id
    /// - Returns: api 응답형식. SongModel 로 변환 후 사용해야함
    private func fetchMusicById(id: Int) async throws -> SongResponse {
        let endpoint = "/api/music/\(id)"

        return try await networkService.fetch(endpoint: endpoint)
    }

    /// 썸네일호출. streamUrl 을 변형해서 이미지경로를 생성하고 api 호출해 그 이미지의 바이너리 데이터를 가져온다
    /// - Parameter streamUrl: 음원경로. 음원과 같은 경로에서 파일명만 다른 jpg파일을 가져오기 때문
    /// - Returns: 이미지 Data 형식
    private func fetchThumbnailImage(from streamUrl: String) async throws -> Data {
        let thumbnailUrl = streamUrl.replacingOccurrences(of: M3U8_FILE_NAME, with: THUMBNAIL_FILE_NAME)
        let data =  try await networkService.fetchData(endpoint: thumbnailUrl)

        return data
    }
}
