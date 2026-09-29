import Foundation

/// Identity Toolkit error payload (`{ "error": { "message": "EMAIL_NOT_FOUND" } }`).
struct FirebaseErrorEnvelope: Decodable {
    struct Payload: Decodable {
        let message: String
    }

    let error: Payload

    var code: String { error.message.components(separatedBy: " : ").first ?? error.message }

    var localizedMessage: String {
        switch code {
        case "EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS":
            return "E-mail ou senha incorretos."
        case "USER_DISABLED":
            return "Esta conta está desativada."
        case "TOO_MANY_ATTEMPTS_TRY_LATER":
            return "Muitas tentativas. Tente novamente em alguns minutos."
        case "PASSWORD_LOGIN_DISABLED", "OPERATION_NOT_ALLOWED":
            return "O login por e-mail e senha está desabilitado na conta Goomer desta loja. Use \"Continuar com Google\" ou o código enviado por e-mail."
        case "INVALID_EMAIL":
            return "Informe um e-mail válido."
        case "MISSING_PASSWORD":
            return "Informe sua senha."
        default:
            return "Não foi possível entrar (\(code))."
        }
    }

    static func decode(from data: Data) -> FirebaseErrorEnvelope? {
        try? JSONDecoder().decode(FirebaseErrorEnvelope.self, from: data)
    }
}
