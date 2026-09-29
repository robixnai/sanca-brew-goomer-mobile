import Foundation

/// Live implementation of `CatalogDataProviding` backed by the public Goomer
/// endpoints that power the store's web menu.
struct GoomerCatalogProvider: CatalogDataProviding {
    private let client: HTTPClientProtocol

    init(client: HTTPClientProtocol = HTTPClient()) {
        self.client = client
    }

    func fetchStore() async throws -> Store {
        let dto = try await client.send(.get(GoomerEnvironment.storeInfoURL), as: StoreInfoResponseDTO.self)
        return try dto.toDomain()
    }

    func fetchMenu(at url: URL) async throws -> Menu {
        let dto = try await client.send(.get(url), as: MenuResponseDTO.self)
        return dto.toDomain()
    }
}
