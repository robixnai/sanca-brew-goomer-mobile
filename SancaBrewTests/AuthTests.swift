import XCTest
@testable import SancaBrew

private struct StubAuthProvider: AuthDataProviding {
    var session: UserSession?
    var error: Error?

    func signIn(email: String, password: String) async throws -> UserSession {
        if let error { throw error }
        return session!
    }

    func signInWithGoogle(idToken: String, accessToken: String?) async throws -> UserSession {
        if let error { throw error }
        return session!
    }

    func refresh(_ session: UserSession) async throws -> UserSession {
        if let error { throw error }
        return session.renewed(idToken: "renewed", refreshToken: session.refreshToken, expiresAt: Date().addingTimeInterval(3600))
    }

    func sendPasswordReset(email: String) async throws {
        if let error { throw error }
    }
}

private final class InMemorySessionStore: SessionStoring, @unchecked Sendable {
    private var stored: UserSession?
    init(_ session: UserSession? = nil) { stored = session }
    func load() -> UserSession? { stored }
    func save(_ session: UserSession) { stored = session }
    func clear() { stored = nil }
}

private func makeSession(expiresIn: TimeInterval = 3600, method: SignInMethod = .emailPassword) -> UserSession {
    UserSession(
        uid: "uid-1", email: "cliente@example.com", displayName: "Cliente", photoURL: nil,
        idToken: "token", refreshToken: "refresh",
        expiresAt: Date().addingTimeInterval(expiresIn), method: method
    )
}

@MainActor
final class AuthRepositoryTests: XCTestCase {
    func testRestoresValidSession() async {
        let repository = AuthRepository(provider: StubAuthProvider(), store: InMemorySessionStore(makeSession()))
        await repository.restore()

        XCTAssertTrue(repository.isSignedIn)
    }

    func testExpiredSessionIsRenewedOnRestore() async {
        let repository = AuthRepository(
            provider: StubAuthProvider(session: makeSession()),
            store: InMemorySessionStore(makeSession(expiresIn: -10))
        )
        await repository.restore()

        XCTAssertEqual(repository.state.session?.idToken, "renewed")
    }

    func testSignInFailureSurfacesLocalizedMessage() async {
        let provider = StubAuthProvider(error: APIError.server(code: "PASSWORD_LOGIN_DISABLED", message: "Login por senha desabilitado"))
        let repository = AuthRepository(provider: provider, store: InMemorySessionStore())
        await repository.signIn(email: "a@b.com", password: "123456")

        XCTAssertFalse(repository.isSignedIn)
        XCTAssertEqual(repository.errorMessage, "Login por senha desabilitado")
    }

    func testSignOutClearsStoredSession() async {
        let store = InMemorySessionStore(makeSession())
        let repository = AuthRepository(provider: StubAuthProvider(), store: store)
        await repository.restore()
        repository.signOut()

        XCTAssertNil(store.load())
        XCTAssertFalse(repository.isSignedIn)
    }
}

final class FirebaseWebSessionTests: XCTestCase {
    func testDecodesLocalStorageRecordFromGoogleSignIn() throws {
        let json = """
        {
          "uid": "abc123",
          "email": "cliente@gmail.com",
          "displayName": "Cliente Goomer",
          "photoURL": "https://lh3.googleusercontent.com/a/photo",
          "providerData": [{ "providerId": "google.com", "email": "cliente@gmail.com" }],
          "stsTokenManager": {
            "refreshToken": "AMf-refresh",
            "accessToken": "eyJhbGciOi",
            "expirationTime": 1790683000000
          }
        }
        """
        let session = try XCTUnwrap(FirebaseWebSession.decode(from: json)).toSession()

        XCTAssertEqual(session.uid, "abc123")
        XCTAssertEqual(session.method, .google)
        XCTAssertEqual(session.idToken, "eyJhbGciOi")
        XCTAssertEqual(session.refreshToken, "AMf-refresh")
        XCTAssertEqual(session.initials, "CG")
    }

    func testFirebaseErrorEnvelopeTranslatesKnownCodes() throws {
        let data = Data(#"{"error":{"message":"PASSWORD_LOGIN_DISABLED"}}"#.utf8)
        let envelope = try XCTUnwrap(FirebaseErrorEnvelope.decode(from: data))

        XCTAssertEqual(envelope.code, "PASSWORD_LOGIN_DISABLED")
        XCTAssertTrue(envelope.localizedMessage.contains("Google"))
    }
}
