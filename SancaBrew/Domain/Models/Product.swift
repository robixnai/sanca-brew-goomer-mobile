import Foundation

struct ProductPrice: Hashable, Sendable, Codable, Identifiable {
    let name: String
    let value: Decimal
    let code: String

    var id: String { code + name }
    var displayName: String { name.isEmpty ? "Preço único" : name }
}

struct Product: Hashable, Sendable, Codable, Identifiable {
    let id: Int
    let name: String
    let details: String
    let categoryID: Int
    let categoryName: String
    let smallImageURL: URL?
    let mediumImageURL: URL?
    let largeImageURL: URL?
    let prices: [ProductPrice]
    let isAgeRestricted: Bool
    let startsFrom: Bool

    var startingPrice: Decimal { prices.map(\.value).min() ?? 0 }
    var hasMultiplePrices: Bool { prices.count > 1 }

    var priceDisplay: String {
        let formatted = CurrencyFormatter.string(from: startingPrice)
        return (startsFrom || hasMultiplePrices) ? "a partir de \(formatted)" : formatted
    }

    func matches(_ query: String) -> Bool {
        let needle = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard !needle.isEmpty else { return true }
        let haystack = [name, details, categoryName]
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return haystack.contains(needle)
    }
}

struct MenuCategory: Hashable, Sendable, Codable, Identifiable {
    let id: Int
    let name: String
    let products: [Product]
}

struct Menu: Hashable, Sendable, Codable {
    let categories: [MenuCategory]

    var products: [Product] { categories.flatMap(\.products) }
    var isEmpty: Bool { categories.isEmpty }

    func search(_ query: String) -> [Product] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return products.filter { $0.matches(trimmed) }
    }

    /// Groups the flat product list returned by Goomer preserving the order in
    /// which the store publishes its categories.
    static func make(from products: [Product]) -> Menu {
        var order: [Int] = []
        var grouped: [Int: [Product]] = [:]
        var names: [Int: String] = [:]

        for product in products {
            if grouped[product.categoryID] == nil {
                order.append(product.categoryID)
                names[product.categoryID] = product.categoryName
            }
            grouped[product.categoryID, default: []].append(product)
        }

        let categories = order.map { id in
            MenuCategory(id: id, name: names[id] ?? "", products: grouped[id] ?? [])
        }
        return Menu(categories: categories)
    }
}
