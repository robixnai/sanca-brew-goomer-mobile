import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [Product] = []
    @Published private(set) var isSearching = false

    private var cancellables = Set<AnyCancellable>()

    func bind(to repository: CatalogRepository) {
        guard cancellables.isEmpty else { return }

        $query
            .map { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .removeDuplicates()
            .assign(to: &$isSearching)

        $query
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .combineLatest(repository.$menu)
            .map { query, menu in menu.search(query) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$results)
    }
}
