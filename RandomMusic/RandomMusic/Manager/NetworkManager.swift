import Foundation  // URL, URLRequest, URLSession, Bundle, JSONDecoder 등
import UIKit       // Bundle.main (iOS 앱에서)
import AVFoundation

/// API 통신을 담당하는 매니저
/// NetworkManager.shared.getMusic() 와 같은 형태로 사용
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://drfranken.net:8091"
    private let name = Bundle.main.object(forInfoDictionaryKey: "NAME") as? String ?? ""
    private let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN") as? String ?? ""


    /// 장르별 랜덤곡을 요청
    /// - Warning: 파라미터를 넣지 않으면 선호도에 기반해서 자동으로 랜덤장르를 요청함. 특수한 상황이 아니라면 파라미터 넣지 말고 쓰세요
    /// - Parameter genre: 장르.
    /// - Returns: 바로 쓸 수 있는 SongModel. 썸네일 Data 와 곡정보가 모두 들어있다.
    func getMusic(genre: Genre? = nil) async throws -> SongModel {
        // 음악 정보 호출
        let response = try await fetchRandomMusic(genre: genre)

        // 썸네일 호출
        var thumbnailData: Data? = nil

        if response.thumbnail == 1 {
            do {
                thumbnailData = try await fetchThumbnailImage(from: response.streamUrl)
            } catch {
                print("썸네일 로드 실패: \(error)") // 썸네일 실패해도 음악은 재생 가능
            }
        } else {
            print("썸네일 없는 곡")
        }

        // 썸네일이 들어간 모델로 만들기
        let songModel = SongModel(from: response, thumbnailData: thumbnailData)

        // 곡 정보 DB 저장
        DataManager.shared.insertSongData(from: songModel)

        return songModel
    }

	/// 헤더가 포함된 Asset 생성
    /// - Parameters: 상대경로. (ex. /api/music/stream/33)
    /// - Returns: AVURLAsset. 바로 PlayerItem 에 넣으면 됩니다.
    func createAssetWithHeaders(url: String) -> AVURLAsset? {
        guard let fullUrl = URL(string: "\(baseURL)\(url)") else {
            print("URL 에러")
            return nil
        }

        let headers = [
            "NAME": name,
            "TOKEN": token
        ]

        let asset = AVURLAsset(url: fullUrl, options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ])

        return asset
    }


    /// 장르에 기반한 곡 메타정보(SongResponse)를 가져온다
    /// - Parameter genre: 장르. enum
    /// - Returns: api 응답형식. SongModel 로 변환 후 사용해야함
    private func fetchRandomMusic(genre: Genre? = nil) async throws -> SongResponse {
        var urlString = "\(baseURL)/api/music/random"

        if let genre = genre {
            urlString += "?genre=\(genre.rawValue)"
        }

        return try await performMusicRequest(urlString: urlString)
    }

    /// 곡ID 기반으로 곡정보 호출. 현재 사용안함. 고도화 용
    /// - Parameter id: 곡 id
    /// - Returns: api 응답형식. SongModel 로 변환 후 사용해야함
    private func fetchMusicById(id: Int) async throws -> SongResponse {
        let urlString = "\(baseURL)/api/music/\(id)"
        return try await performMusicRequest(urlString: urlString)
    }

    /// 공통 네트워크 요청 함수
    /// - Parameter urlString: 전체경로 url. https:// 로 시작하는 fullUrl
    /// - Returns: api 응답형식. SongModel 로 변환 후 사용해야함
    private func performMusicRequest(urlString: String) async throws -> SongResponse {
        guard let url = URL(string: urlString) else {
            print("url 형식 에러")
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(name, forHTTPHeaderField: "NAME")
        request.setValue(token, forHTTPHeaderField: "TOKEN")

        let (data, _) = try await URLSession.shared.data(for: request)
        let music = try JSONDecoder().decode(SongResponse.self, from: data)
        print("음악정보 가져옴")
        return music
    }


    /// 썸네일호출. streamUrl 을 변형해서 이미지경로를 생성하고 api 호출해 그 이미지의 바이너리 데이터를 가져온다
    /// - Parameter streamUrl: 음원경로. 음원과 같은 경로에서 파일명만 다른 jpg파일을 가져오기 때문
    /// - Returns: 이미지 Data 형식
    private func fetchThumbnailImage(from streamUrl: String) async throws -> Data {
        print(#function)
        let thumbnailUrl = streamUrl.replacingOccurrences(of: "output.m3u8", with: "cover.jpg")

        guard let url = URL(string: "\(baseURL)\(thumbnailUrl)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(name, forHTTPHeaderField: "NAME")
        request.setValue(token, forHTTPHeaderField: "TOKEN")

        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

}

