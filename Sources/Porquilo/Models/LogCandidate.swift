import Foundation

struct LogCandidate: Equatable {
    var foodId: UUID
    var foodName: String
    var sourceName: String
    var result: FoodSearchResult
}

extension LogCandidate {
    init(result: FoodSearchResult) {
        self.init(foodId: result.id, foodName: result.name, sourceName: result.sourceName, result: result)
    }
}
