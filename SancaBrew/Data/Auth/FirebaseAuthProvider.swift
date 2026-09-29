import Foundation

/// Native Identity Toolkit (Firebase Auth) REST client for the `goomer-sso`
/// project, used for e-mail/password sign in, Google credential exchange and
/// token renewal — no third-party SDK required.
struct FirebaseAuthProvider: AuthDataProviding {
    private let client: HTTPClientProtocol

    init(client: HTTPClientProtocol = HTTPClient()) {
        self.client = client
    }

    private func endpoint(_ path: String, host: String = "identitytoolkit.googleapis.com", version: String = "v1") throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/\(version)/\(path)"
        components.queryItems = [URLQueryItem(name: "key", value: GoomerEnvironment.firebaseAPIKey)]
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    // MARK: - Requests / responses

    private struct PasswordRequest: Encodable {
        let email: String
        let password: String
        let returnSecureToken = true
    }

    private struct IdpRequest: Encodable {
        let postBody: String
        let requestUri: String
        let returnIdpCredential = true
        let returnSecureToken = true
    }

    private struct OobRequest: Encodable {
        let requestType: String
        let email: String
    }

    private struct SignInResponse: Decodable {
        let localId: String
        let email: String?
        let displayName: String?
        let photoUrl: String?
        let idToken: String
        let refreshToken: String
        let expiresIn: String

        func toSession(method: SignInMethod) -> UserSession {
            UserSession(
                uid: localId,
                email: email,
                displayName: displayName,
                photoURL: photoUrl.flatMap(URL.init(string:)),
                idToken: idToken,
                refreshToken: refreshToken,
                expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn) ?? 3600),
                method: method
            )
        }
    }

    private struct RefreshResponse: Decodable {
        let id_token: String
        let refresh_token: String
        let expires_in: String
    }

    // MARK: - AuthDataProviding

    func signIn(email: String, password: String) async throws -> UserSession {
        let request = try HTTPRequest.json(
            endpoint("accounts:signInWithPassword"),
            body: PasswordRequest(email: email, password: password)
        )
        let response = try await client.send(request, as: SignInResponse.self)
        return response.toSession(method: .emailPassword)
    }

    func signInWithGoogle(idToken: String, accessToken: String?) async throws -> UserSession {
        var postBody = "id_token=\(idToken)&providerId=google.com"
        if let accessToken {
            postBody += "&access_token=\(accessToken)"
        }
        let request = try HTTPRequest.json(
            endpoint("accounts:signInWithIdp"),
            body: IdpRequest(postBody: postBody, requestUri: GoomerEnvironment.webBaseURL.absoluteString)
        )
        let response = try await client.send(request, as: SignInResponse.self)
        return response.toSession(method: .google)
    }

    func refresh(_ session: UserSession) async throws -> UserSession {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "securetoken.googleapis.com"
        components.path = "/v1/token"
        components.queryItems = [URLQueryItem(name: "key", value: GoomerEnvironment.firebaseAPIKey)]
        guard let url = components.url else { throw APIError.invalidURL }

        var request = HTTPRequest(url: url, method: .post)
        request.headers["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = "grant_type=refresh_token&refresh_token=\(session.refreshToken)".data(using: .utf8)

        let response = try await client.send(request, as: RefreshResponse.self)
        return session.renewed(
            idToken: response.id_token,
            refreshToken: response.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expires_in) ?? 3600)
        )
    }

    func sendPasswordReset(email: String) async throws {
        let request = try HTTPRequest.json(
            endpoint("accounts:sendOobCode"),
            body: OobRequest(requestType: "PASSWORD_RESET", email: email)
        )
        _ = try await client.data(for: request)
    }
}
