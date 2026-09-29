import SwiftUI

/// First screen of the app: it shows the store branding while the catalog is
/// downloaded and the images are warmed up.
struct SplashView: View {
    @EnvironmentObject private var catalog: CatalogRepository

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.card],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                StoreLogo(url: catalog.store?.logoURL, size: 132)

                VStack(spacing: 6) {
                    Text(catalog.store?.name ?? "Sanca Brew")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("A Casa do Cervejeiro")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if case let .failed(message) = catalog.phase {
                    VStack(spacing: 16) {
                        Text(message)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Tentar novamente") {
                            Task { await catalog.reload() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView(value: catalog.phase.progress)
                            .tint(Theme.accent)
                        Text(catalog.phase.title)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                    }
                }
            }
            .padding(32)
        }
        .foregroundStyle(.white)
    }
}

struct StoreLogo: View {
    let url: URL?
    var size: CGFloat = 64

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFill()
            default:
                Image(systemName: "mug.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(size / 4)
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(width: size, height: size)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
    }
}
