import Foundation

struct OpeningHour: Hashable, Sendable, Codable {
    let fromDay: String
    let toDay: String
    let opensAt: String
    let closesAt: String

    var displayText: String {
        let days = fromDay == toDay ? fromDay : "\(fromDay) - \(toDay)"
        return "\(days)  \(opensAt) às \(closesAt)"
    }
}

/// Everything the app needs to render the store identity and its rules.
struct Store: Hashable, Sendable, Codable {
    let id: Int
    let slug: String
    let name: String
    let specialty: String
    let about: String
    let welcomeMessage: String
    let address: String
    let logoURL: URL?
    let primaryColorHex: String
    let secondaryColorHex: String
    let whatsappPhone: String
    let menuURL: URL
    let openingHours: [OpeningHour]
    let isTemporarilyClosed: Bool
    let isClosed: Bool
    let deliveryEnabled: Bool
    let takeawayEnabled: Bool
    let deliveryFee: Decimal
    let freeDeliveryMinimum: Decimal?
    let deliveryAverageTime: String

    var freeDeliveryHighlight: String? {
        guard let freeDeliveryMinimum, freeDeliveryMinimum > 0 else { return nil }
        return "Entrega grátis em pedidos acima de \(CurrencyFormatter.string(from: freeDeliveryMinimum))"
    }

    var whatsappURL: URL? {
        let digits = whatsappPhone.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "https://wa.me/\(digits)")
    }
}
