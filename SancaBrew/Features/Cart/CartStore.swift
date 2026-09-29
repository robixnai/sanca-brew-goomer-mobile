import Combine
import Foundation

struct CartItem: Identifiable, Hashable, Sendable {
    let product: Product
    let price: ProductPrice
    var quantity: Int
    var note: String = ""

    var id: String { "\(product.id)-\(price.id)" }
    var total: Decimal { price.value * Decimal(quantity) }
}

/// In-memory cart shared by the whole app. The order itself is completed on the
/// Goomer checkout (the only place allowed to create orders), pre-filled with
/// these items.
@MainActor
final class CartStore: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published private(set) var total: Decimal = 0
    @Published private(set) var itemCount: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        $items
            .map { $0.reduce(Decimal(0)) { $0 + $1.total } }
            .assign(to: &$total)

        $items
            .map { $0.reduce(0) { $0 + $1.quantity } }
            .assign(to: &$itemCount)
    }

    func add(_ product: Product, price: ProductPrice, quantity: Int = 1, note: String = "") {
        let identifier = "\(product.id)-\(price.id)"
        if let index = items.firstIndex(where: { $0.id == identifier }) {
            items[index].quantity += quantity
            if !note.isEmpty { items[index].note = note }
        } else {
            items.append(CartItem(product: product, price: price, quantity: quantity, note: note))
        }
    }

    func setQuantity(_ quantity: Int, for item: CartItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
    }

    func remove(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }

    func clear() {
        items.removeAll()
    }

    /// Human readable order summary, used for the WhatsApp fallback the store
    /// advertises on its own page.
    func whatsappMessage(storeName: String) -> String {
        var lines = ["Olá! Gostaria de fazer um pedido no \(storeName):", ""]
        for item in items {
            let priceLabel = item.price.name.isEmpty ? "" : " (\(item.price.name))"
            lines.append("• \(item.quantity)x \(item.product.name)\(priceLabel) — \(CurrencyFormatter.string(from: item.total))")
            if !item.note.isEmpty { lines.append("   obs: \(item.note)") }
        }
        lines.append("")
        lines.append("Total: \(CurrencyFormatter.string(from: total))")
        return lines.joined(separator: "\n")
    }
}
