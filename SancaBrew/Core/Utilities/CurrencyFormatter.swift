import Foundation

enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.currencyCode = "BRL"
        return formatter
    }()

    static func string(from value: Decimal) -> String {
        formatter.string(from: value as NSDecimalNumber) ?? "R$ 0,00"
    }
}
