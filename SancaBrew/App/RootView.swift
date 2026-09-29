import SwiftUI

struct RootView: View {
    @EnvironmentObject private var catalog: CatalogRepository
    @EnvironmentObject private var auth: AuthRepository
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if catalog.isReady {
                MainTabView()
                    .transition(.opacity)
            } else {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: catalog.isReady)
        .task {
            async let bootstrap: Void = catalog.bootstrap()
            async let restore: Void = auth.restore()
            _ = await (bootstrap, restore)
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task { await auth.refreshIfNeeded() }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var cart: CartStore

    var body: some View {
        TabView {
            MenuView()
                .tabItem { Label("Cardápio", systemImage: "list.bullet.rectangle") }

            SearchView()
                .tabItem { Label("Busca", systemImage: "magnifyingglass") }

            CartView()
                .tabItem { Label("Carrinho", systemImage: "cart") }
                .badge(cart.itemCount)

            ProfileView()
                .tabItem { Label("Conta", systemImage: "person.crop.circle") }
        }
    }
}
