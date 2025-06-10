import Foundation  // URL, URLRequest, URLSession, Bundle, JSONDecoder 등
import UIKit       // Bundle.main (iOS 앱에서)
import AVFoundation

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://drfranken.net:8091"
    private let name = Bundle.main.object(forInfoDictionaryKey: "NAME") as? String ?? ""
    private let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN") as? String ?? ""


    // 랜덤 곡을 바로 SongModel로 반환
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


    // 헤더가 포함된 Asset 생성
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

    // 랜덤 음악 가져오기
    private func fetchRandomMusic(genre: Genre? = nil) async throws -> SongResponse {
        var urlString = "\(baseURL)/api/music/random"

        if let genre = genre {
            urlString += "?genre=\(genre.rawValue)"
        }

        return try await performMusicRequest(urlString: urlString)
    }

    // ID로 음악 가져오기 (추후 사용할 가능성이 있어 만들어놓음)
    private func fetchMusicById(id: Int) async throws -> SongResponse {
        let urlString = "\(baseURL)/api/music/\(id)"
        return try await performMusicRequest(urlString: urlString)
    }

    // 공통 네트워크 요청 함수
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

    // 썸네일 가져오기
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

