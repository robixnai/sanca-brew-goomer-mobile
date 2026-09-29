import SwiftUI

struct ProductDetailView: View {
    let product: Product

    @EnvironmentObject private var cart: CartStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPrice: ProductPrice?
    @State private var quantity = 1
    @State private var note = ""
    @State private var didAdd = false

    private var price: ProductPrice? { selectedPrice ?? product.prices.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let url = product.largeImageURL ?? product.mediumImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.06))
                    }
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.categoryName.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.accent)
                    Text(product.name)
                        .font(.title3.bold())
                    if product.isAgeRestricted {
                        Label("Venda proibida para menores de 18 anos", systemImage: "18.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if !product.details.isEmpty {
                        Text(product.details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if product.hasMultiplePrices {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Escolha uma opção")
                            .font(.subheadline.weight(.semibold))
                        ForEach(product.prices) { option in
                            Button {
                                selectedPrice = option
                            } label: {
                                HStack {
                                    Image(systemName: option == price ? "largecircle.fill.circle" : "circle")
                                    Text(option.displayName)
                                    Spacer()
                                    Text(CurrencyFormatter.string(from: option.value))
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Observações")
                        .font(.subheadline.weight(.semibold))
                    TextField("Ex.: entregar gelado", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(12)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Stepper("Quantidade: \(quantity)", value: $quantity, in: 1...99)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                guard let price else { return }
                cart.add(product, price: price, quantity: quantity, note: note)
                didAdd = true
            } label: {
                HStack {
                    Text("Adicionar")
                    Spacer()
                    Text(CurrencyFormatter.string(from: (price?.value ?? 0) * Decimal(quantity)))
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Adicionado ao carrinho", isPresented: $didAdd) {
            Button("Continuar comprando") { dismiss() }
            Button("Ficar aqui", role: .cancel) {}
        }
    }
}
