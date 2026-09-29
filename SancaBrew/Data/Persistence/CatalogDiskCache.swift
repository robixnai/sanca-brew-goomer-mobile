import Foundation

/// Keeps the last successful catalog on disk so the app opens instantly (and
/// works offline) while a fresh copy is fetched in the background.
actor CatalogDiskCache: CatalogCaching {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileName: String = "catalog-snapshot.json") {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent(fileName)
    }

    func load() -> CatalogSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(CatalogSnapshot.self, from: data)
    }

    func save(_ snapshot: CatalogSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
