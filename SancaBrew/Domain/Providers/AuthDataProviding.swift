import Foundation

protocol AuthDataProviding: Sendable {
    /// Native e-mail + password sign in against the store's Identity Toolkit project.
    func signIn(email: String, password: String) async throws -> UserSession
    /// Exchanges a Google ID token for a Goomer (Firebase) session.
    func signInWithGoogle(idToken: String, accessToken: String?) async throws -> UserSession
    func refresh(_ session: UserSession) async throws -> UserSession
    func sendPasswordReset(email: String) async throws
}
