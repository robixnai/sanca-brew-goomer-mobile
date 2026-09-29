import Foundation

/// `GET https://www.goomer.app/webmenu/{slug}/menu/{version}?provider=ggo`
struct MenuResponseDTO: Decodable {
    let products: [ProductDTO]

    struct ImagesDTO: Decodable {
        let small: String?
        let medium: String?
        let large: String?
    }

    struct PriceDTO: Decodable {
        let name: String?
        let price: Decimal?
        let code: String?
    }

    struct ProductDTO: Decodable {
        let id: Int
        let name: String
        let description: String?
        let groupID: Int
        let groupName: String
        let images: ImagesDTO?
        let prices: [PriceDTO]
        let limitAge: Bool?
        let minPriceFlag: Bool?

        enum CodingKeys: String, CodingKey {
            case id, name, description, images, prices
            case groupID = "group_id"
            case groupName = "group_name"
            case limitAge = "limit_age"
            case minPriceFlag = "min_price_flag"
        }
    }

    func toDomain() -> Menu {
        let products: [Product] = self.products.map { dto in
            Product(
                id: dto.id,
                name: dto.name.trimmingCharacters(in: .whitespacesAndNewlines),
                details: (dto.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                categoryID: dto.groupID,
                categoryName: dto.groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                smallImageURL: dto.images?.small.flatMap(URL.init(string:)),
                mediumImageURL: dto.images?.medium.flatMap(URL.init(string:)),
                largeImageURL: dto.images?.large.flatMap(URL.init(string:)),
                prices: dto.prices.enumerated().map { index, price in
                    ProductPrice(
                        name: (price.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                        value: price.price ?? 0,
                        code: price.code ?? String(index)
                    )
                },
                isAgeRestricted: dto.limitAge ?? false,
                startsFrom: dto.minPriceFlag ?? false
            )
        }
        return Menu.make(from: products)
    }
}
