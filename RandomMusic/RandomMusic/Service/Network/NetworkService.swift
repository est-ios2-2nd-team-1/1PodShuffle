//
//  NetworkManager.swift
//  RandomMusic
//
//  Created by drfranken on 6/12/25.
//

import Foundation

/// 네트워크 관련 기능 '민' 담당한다.
class NetworkService {
    private let baseURL = "https://drfranken.net:8091"
    private let name = Bundle.main.object(forInfoDictionaryKey: "NAME") as? String ?? ""
    private let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN") as? String ?? ""

    /// Decodable 인 데이터를 받아서 SongResponse 등으로 파싱하는 함수
    func fetch<T: Decodable>(endpoint: String) async throws -> T {
        let request = try makeRequest(endpoint: endpoint)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }


    /// 디코딩이 필요없는 Data 타입을 반환하는데 쓰는 함수
    func fetchData(endpoint: String) async throws -> Data {
        let request = try makeRequest(endpoint: endpoint)
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }


    /// 공통 리퀘스트 생성
    func makeRequest(endpoint: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(name, forHTTPHeaderField: "NAME")
        request.setValue(token, forHTTPHeaderField: "TOKEN")
        return request
    }


}
