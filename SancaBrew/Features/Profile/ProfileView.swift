import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthRepository
    @EnvironmentObject private var catalog: CatalogRepository

    var body: some View {
        NavigationStack {
            Group {
                switch auth.state {
                case .restoring:
                    ProgressView("Carregando sua conta…")
                case .signedOut:
                    LoginView()
                case let .signedIn(session):
                    signedIn(session)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Conta")
        }
    }

    @ViewBuilder
    private func signedIn(_ session: UserSession) -> some View {
        List {
            Section {
                HStack(spacing: 14) {
                    AsyncImage(url: session.photoURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Text(session.initials)
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Theme.accent)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.displayName ?? "Cliente Sanca Brew")
                            .font(.headline)
                        if let email = session.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(methodLabel(session.method))
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .listRowBackground(Theme.card)

            if let store = catalog.store {
                Section("Loja") {
                    NavigationLink("Informações da loja") { StoreInfoView(store: store) }
                    if let url = store.whatsappURL {
                        Link("Falar com a loja no WhatsApp", destination: url)
                    }
                }
                .listRowBackground(Theme.card)
            }

            Section {
                Button("Sair da conta", role: .destructive) { auth.signOut() }
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
    }

    private func methodLabel(_ method: SignInMethod) -> String {
        switch method {
        case .google: return "Conectado com Google"
        case .emailPassword: return "Conectado com e-mail e senha"
        case .emailCode: return "Conectado com código por e-mail"
        }
    }
}
