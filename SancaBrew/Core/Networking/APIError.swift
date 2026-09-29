import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case transport(String)
    case unacceptableStatus(Int)
    case decoding(String)
    case unauthorized
    case server(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Endereço inválido."
        case let .transport(reason):
            return "Falha de conexão: \(reason)"
        case let .unacceptableStatus(code):
            return "O servidor respondeu com o código \(code)."
        case let .decoding(reason):
            return "Não foi possível interpretar a resposta: \(reason)"
        case .unauthorized:
            return "Sessão expirada. Entre novamente."
        case let .server(_, message):
            return message
        }
    }
}
