import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var catalog: CatalogRepository
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isSearching {
                    ContentUnavailableView(
                        "Busque no cardápio",
                        systemImage: "magnifyingglass",
                        description: Text("Encontre cervejas, maltes, lúpulos, kits e equipamentos.")
                    )
                } else if viewModel.results.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.results) { product in
                                NavigationLink(value: product) {
                                    ProductRow(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Busca")
            .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
            .searchable(text: $viewModel.query, prompt: "O que você procura?")
        }
        .onAppear { viewModel.bind(to: catalog) }
    }
}
