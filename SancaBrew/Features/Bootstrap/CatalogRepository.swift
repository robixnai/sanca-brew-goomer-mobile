import Combine
import Foundation

/// Loading phases surfaced by the splash screen while the catalog is warmed up.
enum BootstrapPhase: Equatable, Sendable {
    case idle
    case loadingStore
    case loadingMenu
    case warmingImages
    case ready
    case failed(String)

    var title: String {
        switch self {
        case .idle: return "Iniciando…"
        case .loadingStore: return "Conectando à loja…"
        case .loadingMenu: return "Baixando o cardápio…"
        case .warmingImages: return "Preparando as imagens…"
        case .ready: return "Tudo pronto!"
        case .failed: return "Não foi possível carregar"
        }
    }

    var progress: Double {
        switch self {
        case .idle: return 0.05
        case .loadingStore: return 0.25
        case .loadingMenu: return 0.6
        case .warmingImages: return 0.85
        case .ready: return 1
        case .failed: return 1
        }
    }
}

/// Single source of truth for the catalog. Fetches the store and its menu up
/// front (the "robot" pass the app does before showing any content), caches the
/// result on disk and republishes it to every view model.
@MainActor
final class CatalogRepository: ObservableObject {
    @Published private(set) var store: Store?
    @Published private(set) var menu: Menu = Menu(categories: [])
    @Published private(set) var phase: BootstrapPhase = .idle
    @Published private(set) var lastUpdate: Date?

    private let provider: CatalogDataProviding
    private let cache: CatalogCaching
    private let imageWarmer: ImageWarming

    init(
        provider: CatalogDataProviding = GoomerCatalogProvider(),
        cache: CatalogCaching = CatalogDiskCache(),
        imageWarmer: ImageWarming = ImageWarmer()
    ) {
        self.provider = provider
        self.cache = cache
        self.imageWarmer = imageWarmer
    }

    var isReady: Bool { phase == .ready }

    func bootstrap() async {
        if let snapshot = await cache.load() {
            store = snapshot.store
            menu = snapshot.menu
            lastUpdate = snapshot.updatedAt
        }
        await reload()
    }

    func reload() async {
        do {
            phase = .loadingStore
            let store = try await provider.fetchStore()
            self.store = store

            phase = .loadingMenu
            let menu = try await provider.fetchMenu(at: store.menuURL)
            self.menu = menu

            phase = .warmingImages
            await imageWarmer.warm(urls: menu.products.prefix(24).compactMap(\.smallImageURL))

            lastUpdate = Date()
            await cache.save(CatalogSnapshot(store: store, menu: menu, updatedAt: Date()))
            phase = .ready
        } catch {
            if store != nil, !menu.isEmpty {
                // Falls back to the cached catalog instead of blocking the app.
                phase = .ready
            } else {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}
