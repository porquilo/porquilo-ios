import Foundation

struct FoodSearchResult: Identifiable, Equatable, Decodable {
    var id: UUID
    var name: String
    var sourceName: String
    var subtitle: String
    var calorieDisplay: String
    var isTopMatch: Bool
}
