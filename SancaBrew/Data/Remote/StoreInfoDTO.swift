import Foundation

/// `GET /v2/establishments/{slug}/info?mode=slug&provider=ggo`
struct StoreInfoResponseDTO: Decodable {
    let info: InfoDTO
    let settings: SettingsDTO

    struct HourDTO: Decodable, Hashable {
        let from: String
        let to: String
        let open: String
        let close: String
    }

    struct InfoDTO: Decodable {
        let id: Int
        let name: String
        let address: String
        let menu: String
        let hours: [HourDTO]
        let orderPhone: String?
        let welcomeMessage: String?
        let logo: String?
        let colorPrimary: String?
        let colorSecondary: String?
        let deliveryFee: Decimal?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)
            id = Int(Loose.string(container, "id") ?? "0") ?? 0
            name = Loose.string(container, "name") ?? ""
            address = Loose.string(container, "address") ?? ""
            menu = Loose.string(container, "menu") ?? ""
            hours = (try? container.decode([HourDTO].self, forKey: DynamicCodingKey(stringValue: "hours")!)) ?? []
            orderPhone = Loose.string(container, "order_phone")
            welcomeMessage = Loose.string(container, "welcome_message")
            logo = Loose.string(container, "logo")
            colorPrimary = Loose.string(container, "color_1")
            colorSecondary = Loose.string(container, "color_3")
            deliveryFee = Loose.decimal(container, "delivery_fee")
        }
    }

    struct SettingsDTO: Decodable {
        let slug: String
        let specialty: String
        let about: String
        let splashMessage: String
        let whatsappPhone: String
        let menuURL: String
        let mainColor: String
        let secondaryColor: String
        let logoURL: String
        let isTemporarilyClosed: Bool
        let isClosed: Bool
        let deliveryEnabled: Bool
        let takeawayEnabled: Bool
        let freeDeliveryEnabled: Bool
        let freeDeliveryMinimum: Decimal?
        let deliveryAverageTime: String

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)
            slug = Loose.string(container, "slug") ?? GoomerEnvironment.storeSlug
            specialty = Loose.string(container, "specialty_name") ?? ""
            about = Loose.string(container, "about") ?? ""
            splashMessage = Loose.string(container, "mm_splash_screen_message") ?? ""
            whatsappPhone = Loose.string(container, "mm_whatsapp_phone_number") ?? ""
            menuURL = Loose.string(container, "menu_url") ?? ""
            mainColor = Loose.string(container, "mm_main_color") ?? "#2B0D61"
            secondaryColor = Loose.string(container, "mm_secondary_color") ?? "#C7DAAF"
            logoURL = Loose.string(container, "mm_logo_url") ?? ""
            isTemporarilyClosed = Loose.bool(container, "mm_temporarily_closed") ?? false
            isClosed = Loose.bool(container, "mm_store_closed") ?? false
            deliveryEnabled = Loose.bool(container, "mm_delivery_enabled") ?? false
            takeawayEnabled = Loose.bool(container, "mm_takeaway_enabled") ?? false
            freeDeliveryEnabled = Loose.bool(container, "mm_free_delivery_enabled") ?? false
            freeDeliveryMinimum = Loose.decimal(container, "mm_free_delivery_minimum_value")
            deliveryAverageTime = Loose.string(container, "mm_delivery_average_time") ?? ""
        }
    }

    func toDomain() throws -> Store {
        guard let menuURL = GoomerEnvironment.menuURL(from: settings.menuURL.isEmpty ? info.menu : settings.menuURL) else {
            throw APIError.invalidURL
        }
        return Store(
            id: Int(GoomerEnvironment.storeID),
            slug: settings.slug,
            name: info.name,
            specialty: settings.specialty,
            about: settings.about,
            welcomeMessage: settings.splashMessage.isEmpty ? (info.welcomeMessage ?? "") : settings.splashMessage,
            address: info.address,
            logoURL: URL(string: settings.logoURL.isEmpty ? (info.logo ?? "") : settings.logoURL),
            primaryColorHex: settings.secondaryColor,
            secondaryColorHex: settings.mainColor,
            whatsappPhone: settings.whatsappPhone.isEmpty ? (info.orderPhone ?? "") : settings.whatsappPhone,
            menuURL: menuURL,
            openingHours: info.hours.map {
                OpeningHour(fromDay: $0.from, toDay: $0.to, opensAt: $0.open, closesAt: $0.close)
            },
            isTemporarilyClosed: settings.isTemporarilyClosed,
            isClosed: settings.isClosed,
            deliveryEnabled: settings.deliveryEnabled,
            takeawayEnabled: settings.takeawayEnabled,
            deliveryFee: info.deliveryFee ?? 0,
            freeDeliveryMinimum: settings.freeDeliveryEnabled ? settings.freeDeliveryMinimum : nil,
            deliveryAverageTime: settings.deliveryAverageTime
        )
    }
}
