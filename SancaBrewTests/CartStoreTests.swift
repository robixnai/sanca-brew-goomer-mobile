import XCTest
@testable import SancaBrew

@MainActor
final class CartStoreTests: XCTestCase {
    private func product(id: Int = 1, prices: [ProductPrice] = [ProductPrice(name: "", value: 12.5, code: "0")]) -> Product {
        Product(
            id: id, name: "Pale Ale", details: "", categoryID: 1, categoryName: "Cervejas",
            smallImageURL: nil, mediumImageURL: nil, largeImageURL: nil,
            prices: prices, isAgeRestricted: true, startsFrom: false
        )
    }

    func testAddingSameVariantIncrementsQuantity() {
        let cart = CartStore()
        let item = product()
        cart.add(item, price: item.prices[0])
        cart.add(item, price: item.prices[0], quantity: 2)

        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.itemCount, 3)
        XCTAssertEqual(cart.total, 37.5)
    }

    func testDifferentVariantsAreSeparateLines() {
        let cart = CartStore()
        let item = product(prices: [
            ProductPrice(name: "473ml", value: 25, code: "0"),
            ProductPrice(name: "600ml", value: 32, code: "1")
        ])
        cart.add(item, price: item.prices[0])
        cart.add(item, price: item.prices[1])

        XCTAssertEqual(cart.items.count, 2)
        XCTAssertEqual(cart.total, 57)
    }

    func testSettingZeroQuantityRemovesItem() {
        let cart = CartStore()
        let item = product()
        cart.add(item, price: item.prices[0])
        cart.setQuantity(0, for: cart.items[0])

        XCTAssertTrue(cart.items.isEmpty)
        XCTAssertEqual(cart.total, 0)
    }

    func testWhatsappMessageListsItemsAndTotal() {
        let cart = CartStore()
        let item = product()
        cart.add(item, price: item.prices[0], quantity: 2, note: "gelada")
        let message = cart.whatsappMessage(storeName: "Sanca Brew")

        XCTAssertTrue(message.contains("2x Pale Ale"))
        XCTAssertTrue(message.contains("obs: gelada"))
        XCTAssertTrue(message.contains("Total"))
    }
}
