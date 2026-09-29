import SwiftUI

struct StoreInfoView: View {
    let store: Store

    var body: some View {
        List {
            Section("Sobre") {
                Text(store.about.isEmpty ? store.welcomeMessage : store.about)
                    .font(.subheadline)
            }
            .listRowBackground(Theme.card)

            Section("Horários") {
                ForEach(store.openingHours, id: \.self) { hour in
                    Text(hour.displayText)
                        .font(.subheadline.monospacedDigit())
                }
            }
            .listRowBackground(Theme.card)

            Section("Entrega e retirada") {
                Label(store.deliveryEnabled ? "Entrega disponível" : "Entrega indisponível", systemImage: "bicycle")
                Label(store.takeawayEnabled ? "Retirada no local" : "Sem retirada no local", systemImage: "bag")
                if let minimum = store.freeDeliveryMinimum, minimum > 0 {
                    Label("Entrega grátis acima de \(CurrencyFormatter.string(from: minimum))", systemImage: "gift")
                }
                if !store.deliveryAverageTime.isEmpty {
                    Label("Tempo médio: \(store.deliveryAverageTime) min", systemImage: "clock")
                }
            }
            .listRowBackground(Theme.card)

            Section("Endereço") {
                Text(store.address)
                if let url = store.whatsappURL {
                    Link("Falar no WhatsApp", destination: url)
                }
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("A loja")
        .navigationBarTitleDisplayMode(.inline)
    }
}
