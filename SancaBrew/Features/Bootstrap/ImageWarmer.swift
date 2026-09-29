import Foundation

protocol ImageWarming: Sendable {
    func warm(urls: [URL]) async
}

/// Pre-populates `URLCache` so the first scroll through the menu renders
/// immediately after the splash screen.
struct ImageWarmer: ImageWarming {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func warm(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = try? await session.data(from: url)
                }
            }
        }
    }
}
