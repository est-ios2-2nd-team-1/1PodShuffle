import Foundation  // URL, URLRequest, URLSession, Bundle, JSONDecoder 등
import UIKit       // Bundle.main (iOS 앱에서)
import AVFoundation

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://drfranken.net:8091"
    private let name = Bundle.main.object(forInfoDictionaryKey: "NAME") as? String ?? ""
    private let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN") as? String ?? ""

    // 랜덤 음악 가져오기 (장르 선택 가능)
    func fetchRandomMusic(genre: Genre? = nil) async throws -> SongResponse {
        print(#function)
        var urlString = "\(baseURL)/api/music/random"

        if let genre = genre {
            urlString += "?genre=\(genre.rawValue)"
        }

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



    // 썸네일 이미지 가져오기
    func fetchThumbnailImage(from streamUrl: String) async throws -> Data {
        print(#function)
        let thumbnailUrl = streamUrl.replacingOccurrences(of: "output.m3u8", with: "cover.jpg")

        guard let url = URL(string: "\(baseURL)\(thumbnailUrl)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(name, forHTTPHeaderField: "NAME")
        request.setValue(token, forHTTPHeaderField: "TOKEN")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return data
        } catch {
            throw error
        }
    }

    func convertToFullUrl(url: String)  -> URL? {
        let fullUrl = URL(string: "\(baseURL)\(url)")
        return fullUrl
    }


    // 헤더가 포함된 Asset 생성
    func createAssetWithHeaders(url: URL) -> AVURLAsset {
        print(#function)
        let headers = [
            "NAME": name,
            "TOKEN": token
        ]

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ])

        return asset
    }

    

}

