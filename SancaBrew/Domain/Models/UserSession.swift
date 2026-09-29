import Foundation

enum SignInMethod: String, Codable, Sendable {
    case emailPassword
    case google
    case emailCode
}

struct UserSession: Codable, Hashable, Sendable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let idToken: String
    let refreshToken: String
    let expiresAt: Date
    let method: SignInMethod

    var isExpired: Bool { expiresAt <= Date().addingTimeInterval(60) }

    var initials: String {
        let source = displayName?.isEmpty == false ? displayName! : (email ?? "?")
        let parts = source.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    func renewed(idToken: String, refreshToken: String, expiresAt: Date) -> UserSession {
        UserSession(
            uid: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            idToken: idToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            method: method
        )
    }
}
