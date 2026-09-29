import XCTest
@testable import SancaBrew

final class StoreDecodingTests: XCTestCase {
    func testDecodesStoreInfoWithMixedValueTypes() throws {
        let data = try Fixture.data("store-info")
        let store = try JSONDecoder().decode(StoreInfoResponseDTO.self, from: data).toDomain()

        XCTAssertEqual(store.slug, "sanca-brew-a-casa-do-cervejeiro")
        XCTAssertEqual(store.name, "Sanca Brew - A Casa do Cervejeiro")
        XCTAssertTrue(store.deliveryEnabled)
        XCTAssertEqual(store.freeDeliveryMinimum, 150)
        XCTAssertFalse(store.openingHours.isEmpty)
        XCTAssertTrue(store.menuURL.absoluteString.contains("provider=ggo"))
        XCTAssertNotNil(store.whatsappURL)
    }

    func testFreeDeliveryHighlightIsFormattedInBRL() throws {
        let data = try Fixture.data("store-info")
        let store = try JSONDecoder().decode(StoreInfoResponseDTO.self, from: data).toDomain()

        XCTAssertEqual(store.freeDeliveryHighlight?.contains("150"), true)
    }
}
