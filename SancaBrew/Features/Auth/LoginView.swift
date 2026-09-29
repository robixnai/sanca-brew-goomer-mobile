import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthRepository

    @State private var email = ""
    @State private var password = ""
    @State private var showWebSignIn = false
    @State private var resetSent = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6 && !auth.isWorking
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accent)
                    Text("Entrar")
                        .font(.title2.bold())
                    Text("Faça login e mantenha seus dados salvos para este e os próximos pedidos.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    TextField("E-mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    SecureField("Senha", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submit() }
                }
                .textFieldStyle(.plain)
                .padding(14)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if let message = auth.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                Button(action: submit) {
                    HStack {
                        if auth.isWorking { ProgressView().controlSize(.small) }
                        Text("Entrar com e-mail e senha")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)

                Button("Esqueci minha senha") {
                    Task {
                        await auth.sendPasswordReset(email: email)
                        resetSent = auth.errorMessage == nil
                    }
                }
                .font(.footnote)
                .disabled(!email.contains("@"))

                HStack {
                    Rectangle().frame(height: 1).opacity(0.15)
                    Text("ou").font(.caption).foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).opacity(0.15)
                }

                Button {
                    showWebSignIn = true
                } label: {
                    Label("Continuar com Google", systemImage: "globe")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)

                Text("O login com Google (e o código enviado por e-mail) usa o SSO oficial da Goomer; ao concluir, a sessão passa a valer dentro do app.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showWebSignIn) {
            GoomerWebFlowView(
                title: "Entrar",
                url: GoomerEnvironment.profileWebURL,
                onSession: { session in
                    auth.completeWebSignIn(session)
                    showWebSignIn = false
                }
            )
        }
        .alert("E-mail enviado", isPresented: $resetSent) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text("Se existir uma conta com esse e-mail, você receberá as instruções de redefinição.")
        }
    }

    private func submit() {
        focusedField = nil
        Task { await auth.signIn(email: email, password: password) }
    }
}
