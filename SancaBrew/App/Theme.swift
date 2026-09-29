import SwiftUI

enum Theme {
    static let accent = Color(hex: "#C7DAAF")
    static let background = Color(hex: "#160A2E")
    static let card = Color(hex: "#241046")

    static func color(_ hex: String, fallback: Color) -> Color {
        hex.isEmpty ? fallback : Color(hex: hex)
    }
}

extension Color {
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red, green, blue: Double
        switch sanitized.count {
        case 3:
            red = Double((value >> 8) & 0xF) / 15
            green = Double((value >> 4) & 0xF) / 15
            blue = Double(value & 0xF) / 15
        default:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        }
        self = Color(red: red, green: green, blue: blue)
    }
}
