import Combine
import Foundation

enum AuthState: Equatable {
    case restoring
    case signedOut
    case signedIn(UserSession)

    var session: UserSession? {
        if case let .signedIn(session) = self { return session }
        return nil
    }
}

/// Owns the authentication lifecycle: native e-mail/password sign in, Google
/// sign in bridged from the Goomer web SSO, token renewal and keychain storage.
@MainActor
final class AuthRepository: ObservableObject {
    @Published private(set) var state: AuthState = .restoring
    @Published var errorMessage: String?
    @Published private(set) var isWorking = false

    private let provider: AuthDataProviding
    private let store: SessionStoring

    init(provider: AuthDataProviding = FirebaseAuthProvider(), store: SessionStoring = KeychainSessionStore()) {
        self.provider = provider
        self.store = store
    }

    var isSignedIn: Bool { state.session != nil }

    func restore() async {
        guard let session = store.load() else {
            state = .signedOut
            return
        }
        guard session.isExpired else {
            state = .signedIn(session)
            return
        }
        do {
            let renewed = try await provider.refresh(session)
            persist(renewed)
        } catch {
            store.clear()
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            let session = try await provider.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            persist(session)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func completeWebSignIn(_ webSession: FirebaseWebSession) {
        errorMessage = nil
        persist(webSession.toSession())
    }

    func signInWithGoogle(idToken: String, accessToken: String?) async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            let session = try await provider.signInWithGoogle(idToken: idToken, accessToken: accessToken)
            persist(session)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func sendPasswordReset(email: String) async {
        errorMessage = nil
        do {
            try await provider.sendPasswordReset(email: email)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signOut() {
        store.clear()
        state = .signedOut
    }

    /// Renews the ID token when it is about to expire (used before any
    /// authenticated call and when the app returns to the foreground).
    func refreshIfNeeded() async {
        guard let session = state.session, session.isExpired else { return }
        do {
            persist(try await provider.refresh(session))
        } catch {
            signOut()
        }
    }

    private func persist(_ session: UserSession) {
        store.save(session)
        state = .signedIn(session)
    }
}
