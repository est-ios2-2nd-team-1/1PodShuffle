import Foundation

/// 네트워크 관련 기능 '만' 담당한다.
class NetworkService {
    private let baseURL = "https://drfranken.net:8091"
    private let name = Bundle.main.object(forInfoDictionaryKey: "NAME") as? String ?? ""
    private let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN") as? String ?? ""

    /// json 디코딩할 때 쓰는 함수
    /// - parameter endpoint: 베이스 URL 뒤에 붙일 상대경로
    /// - returns: 제네릭 디코딩된 객체 리턴함
    /// - throws: URL 잘못됐거나 통신 실패하면 오류 던짐
    func fetch<T: Decodable>(endpoint: String) async throws -> T {
        let request = try makeRequest(endpoint: endpoint)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Data만 필요할 때 쓰는 함수
    /// - parameter endpoint: 베이스 URL 뒤에 붙일 상대경로
    /// - returns: 받아온 데이터 그대로 리턴함
    /// - throws: URL 잘못됐거나 통신 실패하면 오류 던짐
    func fetchData(endpoint: String) async throws -> Data {
        let request = try makeRequest(endpoint: endpoint)
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    /// 공통 헤더 들어간 요청 만드는 함수
    /// - parameter endpoint: 베이스 URL 뒤에 붙일 상대경로
    /// - returns: 헤더 포함된 URLRequest 객체
    /// - throws: URL 생성 안되면 오류 던짐
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
