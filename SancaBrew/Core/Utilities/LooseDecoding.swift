import Foundation

/// The Goomer settings payload mixes types for the same field between endpoints
/// (`"true"` vs `true`, `"150"` vs `150`). These helpers decode either shape.
enum Loose {
    static func string(_ container: KeyedDecodingContainer<DynamicCodingKey>, _ key: String) -> String? {
        guard let codingKey = DynamicCodingKey(stringValue: key) else { return nil }
        if let value = try? container.decode(String.self, forKey: codingKey) { return value }
        if let value = try? container.decode(Int.self, forKey: codingKey) { return String(value) }
        if let value = try? container.decode(Double.self, forKey: codingKey) { return String(value) }
        if let value = try? container.decode(Bool.self, forKey: codingKey) { return String(value) }
        return nil
    }

    static func bool(_ container: KeyedDecodingContainer<DynamicCodingKey>, _ key: String) -> Bool? {
        guard let raw = string(container, key) else { return nil }
        switch raw.lowercased() {
        case "true", "1", "yes": return true
        case "false", "0", "no": return false
        default: return nil
        }
    }

    static func decimal(_ container: KeyedDecodingContainer<DynamicCodingKey>, _ key: String) -> Decimal? {
        guard let raw = string(container, key) else { return nil }
        return Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX"))
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}
