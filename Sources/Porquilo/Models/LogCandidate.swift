import Foundation

struct LogCandidate: Equatable {
    enum Origin: Equatable {
        case search
        case barcode
    }

    var foodId: UUID
    var foodName: String
    var sourceName: String
    var origin: Origin
    var result: FoodSearchResult

    /// The food's named serving variants, may be empty.
    var variants: [FoodVariant] { result.variants }

    /// Matches the server's `weight_source` enum for Quick Log entries.
    var weightSource: String {
        switch origin {
        case .search: return "quick_search"
        case .barcode: return "quick_barcode"
        }
    }
}

extension LogCandidate {
    init(result: FoodSearchResult, origin: Origin = .search) {
        self.init(foodId: result.id, foodName: result.name, sourceName: result.sourceName, origin: origin, result: result)
    }
}
