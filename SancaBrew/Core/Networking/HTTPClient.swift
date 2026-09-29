import Foundation

protocol HTTPClientProtocol: Sendable {
    func data(for request: HTTPRequest) async throws -> Data
    func send<T: Decodable>(_ request: HTTPRequest, as type: T.Type) async throws -> T
}

extension HTTPClientProtocol {
    func send<T: Decodable>(_ request: HTTPRequest, as type: T.Type) async throws -> T {
        let data = try await data(for: request)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }
}

/// Thin async/await wrapper around `URLSession` that applies the headers the
/// Goomer endpoints expect (they reject requests without a browser-like origin).
struct HTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let defaultHeaders: [String: String]

    init(session: URLSession = .shared, defaultHeaders: [String: String] = GoomerEnvironment.defaultHeaders) {
        self.session = session
        self.defaultHeaders = defaultHeaders
    }

    func data(for request: HTTPRequest) async throws -> Data {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        for (key, value) in defaultHeaders.merging(request.headers, uniquingKeysWith: { _, new in new }) {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { return data }
        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            if let failure = FirebaseErrorEnvelope.decode(from: data) {
                throw APIError.server(code: failure.code, message: failure.localizedMessage)
            }
            throw APIError.unauthorized
        default:
            if let failure = FirebaseErrorEnvelope.decode(from: data) {
                throw APIError.server(code: failure.code, message: failure.localizedMessage)
            }
            throw APIError.unacceptableStatus(http.statusCode)
        }
    }
}
