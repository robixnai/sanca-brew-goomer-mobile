import XCTest
@testable import SancaBrew

final class MenuDecodingTests: XCTestCase {
    func testDecodesMenuAndGroupsByCategoryPreservingOrder() throws {
        let data = try Fixture.data("menu")
        let menu = try JSONDecoder().decode(MenuResponseDTO.self, from: data).toDomain()

        XCTAssertFalse(menu.isEmpty)
        XCTAssertEqual(menu.products.count, 12)

        let firstCategory = try XCTUnwrap(menu.categories.first)
        XCTAssertEqual(firstCategory.name, "Cervejaria Prússia Bier - MG")
        XCTAssertEqual(firstCategory.id, firstCategory.products.first?.categoryID)
    }

    func testProductPricingAndImages() throws {
        let data = try Fixture.data("menu")
        let menu = try JSONDecoder().decode(MenuResponseDTO.self, from: data).toDomain()
        let product = try XCTUnwrap(menu.products.first)

        XCTAssertEqual(product.startingPrice, 25)
        XCTAssertFalse(product.hasMultiplePrices)
        XCTAssertTrue(product.isAgeRestricted)
        XCTAssertEqual(product.priceDisplay, CurrencyFormatter.string(from: 25))
        XCTAssertNotNil(product.mediumImageURL)
    }

    func testSearchIsDiacriticAndCaseInsensitive() throws {
        let data = try Fixture.data("menu")
        let menu = try JSONDecoder().decode(MenuResponseDTO.self, from: data).toDomain()

        XCTAssertFalse(menu.search("PRUSSIA").isEmpty)
        XCTAssertTrue(menu.search("").isEmpty)
    }

    func testMenuGroupingKeepsPublishedOrder() {
        let make: (Int, Int, String) -> Product = { id, category, name in
            Product(
                id: id, name: name, details: "", categoryID: category, categoryName: name,
                smallImageURL: nil, mediumImageURL: nil, largeImageURL: nil,
                prices: [ProductPrice(name: "", value: 10, code: "0")],
                isAgeRestricted: false, startsFrom: false
            )
        }
        let menu = Menu.make(from: [make(1, 20, "B"), make(2, 10, "A"), make(3, 20, "B")])

        XCTAssertEqual(menu.categories.map(\.id), [20, 10])
        XCTAssertEqual(menu.categories.first?.products.count, 2)
    }
}
