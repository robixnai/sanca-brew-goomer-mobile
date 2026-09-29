import SwiftUI

@main
struct SancaBrewApp: App {
    @StateObject private var catalog = CatalogRepository()
    @StateObject private var auth = AuthRepository()
    @StateObject private var cart = CartStore()

    init() {
        URLCache.shared = URLCache(memoryCapacity: 32 * 1024 * 1024, diskCapacity: 256 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(catalog)
                .environmentObject(auth)
                .environmentObject(cart)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}
