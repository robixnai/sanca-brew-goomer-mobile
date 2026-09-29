import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var catalog: CatalogRepository
    @StateObject private var viewModel = MenuViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    if let store = catalog.store {
                        StoreHeaderView(store: store)
                    }

                    Section {
                        ForEach(viewModel.products(in: viewModel.selectedCategoryID)) { product in
                            NavigationLink(value: product) {
                                ProductRow(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        CategoryPicker(
                            categories: viewModel.categories,
                            selection: $viewModel.selectedCategoryID
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Cardápio")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
            .refreshable { await catalog.reload() }
        }
        .onAppear { viewModel.bind(to: catalog) }
    }
}

struct CategoryPicker: View {
    let categories: [MenuCategory]
    @Binding var selection: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { category in
                        Button {
                            withAnimation(.snappy) { selection = category.id }
                        } label: {
                            Text(category.name)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selection == category.id ? Theme.accent : Theme.card)
                                .foregroundStyle(selection == category.id ? Color.black : Color.white)
                                .clipShape(Capsule())
                        }
                        .id(category.id)
                    }
                }
                .padding(.vertical, 10)
            }
            .onChange(of: selection) { _, newValue in
                guard let newValue else { return }
                withAnimation { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
        .background(Theme.background)
    }
}

struct StoreHeaderView: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                StoreLogo(url: store.logoURL, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.headline)
                    Text(store.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    StoreStatusBadge(store: store)
                }
                Spacer(minLength: 0)
            }

            if let highlight = store.freeDeliveryHighlight {
                Label(highlight, systemImage: "bicycle")
                    .font(.caption.weight(.semibold))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.accent.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            NavigationLink {
                StoreInfoView(store: store)
            } label: {
                Label("Horários, endereço e formas de entrega", systemImage: "info.circle")
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.top, 8)
    }
}

struct StoreStatusBadge: View {
    let store: Store

    private var isOpen: Bool { !(store.isClosed || store.isTemporarilyClosed) }

    var body: some View {
        Text(isOpen ? "Aberto agora" : "Fechado no momento")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isOpen ? Color.green.opacity(0.25) : Color.red.opacity(0.25))
            .foregroundStyle(isOpen ? Color.green : Color.red)
            .clipShape(Capsule())
    }
}

struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                if !product.details.isEmpty {
                    Text(product.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                Text(product.priceDisplay)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            Spacer(minLength: 0)
            ProductThumbnail(url: product.smallImageURL)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ProductThumbnail: View {
    let url: URL?
    var size: CGFloat = 76

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFill()
            case .empty where url != nil:
                ProgressView()
            default:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
