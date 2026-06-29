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
}

extension LogCandidate {
    init(result: FoodSearchResult, origin: Origin = .search) {
        self.init(foodId: result.id, foodName: result.name, sourceName: result.sourceName, origin: origin, result: result)
    }
}
