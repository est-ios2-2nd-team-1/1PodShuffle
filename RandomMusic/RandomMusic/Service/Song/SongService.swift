//
//  SongService.swift
//  RandomMusic
//
//  Created by drfranken on 6/12/25.
//


//import UIKit       // Bundle.main (iOS 앱에서)
import AVFoundation

/// Song 관련 비지니스로직
class SongService {

    // 참조 객체 생성
    let networkService = NetworkService()

    /// 장르별 랜덤곡을 요청
    /// - Warning: 파라미터를 넣지 않으면 선호도에 기반해서 자동으로 랜덤장르를 요청함. 특수한 상황이 아니라면 파라미터 넣지 말고 쓰세요
    /// - Parameter genre: 장르.
    /// - Returns: 바로 쓸 수 있는 SongModel. 썸네일 Data 와 곡정보가 모두 들어있다.
    func getMusic(genre: Genre? = nil) async throws -> SongModel {
        let currentSongIdArr = PlayerManager.shared.playlist.map {$0.id} // 현재 플레이리스트에 있는 곡들의 id 배열

        var realGenre: Genre // 장르가 없으면 장르를 랜덤으로 뽑아서 넣어주기 위해서 새로 선언

        if let genre { // 장르 입력값이 있으면 그대로 사용
            realGenre = genre
        } else { // 장르 입력값이 없으면 선호도 기반으로 랜덤으로 추출
            let pm = PreferenceManager()
            realGenre = pm.selectRandomGenre()
        }

        // 음악 정보 호출. playList 에 이미 있는 곡이라면 재요청.
        var response: SongResponse
        response = try await fetchRandomMusic(genre: realGenre)

        // 썸네일 호출
        var thumbnailData: Data? = nil

        if response.thumbnail == .exists {
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

        return songModel
    }

    // TODO: 작업
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
                let thumbnailData = try await fetchThumbnailImage(from: response.streamUrl)
            }

            songModelList.append(SongModel(from: response, thumbnailData: thumbnailData))
        }

        return songModelList
    }

    /// 헤더가 포함된 Asset 생성
    func createAssetWithHeaders(url: String) throws -> AVURLAsset? {
        let request = try networkService.makeRequest(endpoint: url)
        let headers = request.allHTTPHeaderFields ?? [:]
        let asset = AVURLAsset(url: request.url!, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])

        return asset
    }

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

    private func fetchRandomMusics(genre: Genre? = nil) async throws -> [SongResponse] {
        var endpoint = "/api/music/randomMany/10"
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
        let thumbnailUrl = streamUrl.replacingOccurrences(of: "output.m3u8", with: "cover.jpg")
        let data =  try await networkService.fetchData(endpoint: thumbnailUrl)

        return data
    }
}
