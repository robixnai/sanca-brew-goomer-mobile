import Foundation

/// Read access to the store catalog. The app only ever talks to this protocol so
/// the network, the cache and the previews are interchangeable.
protocol CatalogDataProviding: Sendable {
    func fetchStore() async throws -> Store
    func fetchMenu(at url: URL) async throws -> Menu
}

protocol CatalogCaching: Sendable {
    func load() async -> CatalogSnapshot?
    func save(_ snapshot: CatalogSnapshot) async
}

struct CatalogSnapshot: Codable, Hashable, Sendable {
    let store: Store
    let menu: Menu
    let updatedAt: Date
}
