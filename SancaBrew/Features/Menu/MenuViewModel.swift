import Combine
import Foundation

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var selectedCategoryID: Int?
    @Published private(set) var categories: [MenuCategory] = []

    private var cancellables = Set<AnyCancellable>()

    func bind(to repository: CatalogRepository) {
        guard cancellables.isEmpty else { return }
        repository.$menu
            .map(\.categories)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                guard let self else { return }
                self.categories = categories
                if self.selectedCategoryID == nil || !categories.contains(where: { $0.id == self.selectedCategoryID }) {
                    self.selectedCategoryID = categories.first?.id
                }
            }
            .store(in: &cancellables)
    }

    func products(in categoryID: Int?) -> [Product] {
        guard let categoryID, let category = categories.first(where: { $0.id == categoryID }) else {
            return categories.first?.products ?? []
        }
        return category.products
    }
}
