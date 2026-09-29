import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cart: CartStore
    @EnvironmentObject private var catalog: CatalogRepository
    @EnvironmentObject private var auth: AuthRepository

    @State private var showCheckout = false

    var body: some View {
        NavigationStack {
            Group {
                if cart.items.isEmpty {
                    ContentUnavailableView(
                        "Seu carrinho está vazio",
                        systemImage: "cart",
                        description: Text("Adicione itens do cardápio para continuar.")
                    )
                } else {
                    List {
                        ForEach(cart.items) { item in
                            CartRow(item: item)
                                .listRowBackground(Theme.card)
                        }
                        .onDelete { indexSet in
                            indexSet.map { cart.items[$0] }.forEach(cart.remove)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Carrinho")
            .toolbar {
                if !cart.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Limpar", role: .destructive) { cart.clear() }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !cart.items.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(CurrencyFormatter.string(from: cart.total))
                                .font(.headline)
                        }
                        Button {
                            showCheckout = true
                        } label: {
                            Text(auth.isSignedIn ? "Finalizar pedido" : "Entrar e finalizar pedido")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)

                        if let store = catalog.store, let url = store.whatsappURL {
                            Link(destination: whatsappURL(base: url, store: store)) {
                                Label("Enviar pedido pelo WhatsApp", systemImage: "phone.bubble")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                }
            }
            .sheet(isPresented: $showCheckout) {
                GoomerWebFlowView(
                    title: "Finalizar pedido",
                    url: GoomerEnvironment.checkoutWebURL
                )
            }
        }
    }

    private func whatsappURL(base: URL, store: Store) -> URL {
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "text", value: cart.whatsappMessage(storeName: store.name))]
        return components?.url ?? base
    }
}

struct CartRow: View {
    @EnvironmentObject private var cart: CartStore
    let item: CartItem

    var body: some View {
        HStack(spacing: 12) {
            ProductThumbnail(url: item.product.smallImageURL, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.subheadline.weight(.semibold))
                if !item.price.name.isEmpty {
                    Text(item.price.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(CurrencyFormatter.string(from: item.total))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            Spacer()
            Stepper(
                value: Binding(
                    get: { item.quantity },
                    set: { cart.setQuantity($0, for: item) }
                ),
                in: 0...99
            ) {
                Text("\(item.quantity)")
                    .font(.subheadline.monospacedDigit())
            }
            .labelsHidden()
        }
    }
}
