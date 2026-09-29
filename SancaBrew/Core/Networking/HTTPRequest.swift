import Foundation

struct HTTPRequest: Sendable {
    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
    }

    var url: URL
    var method: Method = .get
    var headers: [String: String] = [:]
    var body: Data?

    static func get(_ url: URL, headers: [String: String] = [:]) -> HTTPRequest {
        HTTPRequest(url: url, method: .get, headers: headers)
    }

    static func json(_ url: URL, body: some Encodable, headers: [String: String] = [:]) throws -> HTTPRequest {
        var request = HTTPRequest(url: url, method: .post, headers: headers)
        request.headers["Content-Type"] = "application/json"
        request.body = try JSONEncoder().encode(body)
        return request
    }
}
