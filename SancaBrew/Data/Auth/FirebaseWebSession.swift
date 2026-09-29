import Foundation

/// Shape of the record the Firebase JavaScript SDK persists in `localStorage`
/// under `firebase:authUser:<apiKey>:[DEFAULT]`.
///
/// Reading it lets the app promote a sign in performed on the Goomer web login
/// (Google or e-mail code — the only providers the store enables) to a native
/// session with a real ID token and refresh token.
struct FirebaseWebSession: Decodable {
    struct TokenManager: Decodable {
        let accessToken: String
        let refreshToken: String
        let expirationTime: Double
    }

    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    let providerId: String?
    let stsTokenManager: TokenManager

    var providerData: [ProviderRecord]?

    struct ProviderRecord: Decodable {
        let providerId: String?
        let email: String?
        let displayName: String?
        let photoURL: String?
    }

    func toSession() -> UserSession {
        let provider = providerData?.first?.providerId ?? providerId
        return UserSession(
            uid: uid,
            email: email ?? providerData?.first?.email,
            displayName: displayName ?? providerData?.first?.displayName,
            photoURL: (photoURL ?? providerData?.first?.photoURL).flatMap(URL.init(string:)),
            idToken: stsTokenManager.accessToken,
            refreshToken: stsTokenManager.refreshToken,
            expiresAt: Date(timeIntervalSince1970: stsTokenManager.expirationTime / 1000),
            method: provider == "google.com" ? .google : .emailCode
        )
    }

    static func decode(from json: String) -> FirebaseWebSession? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(FirebaseWebSession.self, from: data)
    }
}
