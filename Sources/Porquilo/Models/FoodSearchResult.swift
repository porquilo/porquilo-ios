import Foundation

struct FoodSearchResult: Identifiable, Equatable {
    var id: UUID
    var name: String
    var sourceName: String
    var subtitle: String
    /// Nutrient values per 100 g, keyed by server nutrient key (e.g. "calories_kcal").
    var nutrientsPer100g: [String: Double]
    var isTopMatch: Bool

    var caloriesPer100g: Double { nutrientsPer100g["calories_kcal"] ?? 0 }
    var proteinPer100g: Double { nutrientsPer100g["protein_g"] ?? 0 }
    var carbsPer100g: Double { nutrientsPer100g["carbs_g"] ?? 0 }
    var fatPer100g: Double { nutrientsPer100g["fat_g"] ?? 0 }

    var calorieDisplay: String {
        guard caloriesPer100g > 0 else { return "—" }
        return "\(Int(caloriesPer100g.rounded()))/100g"
    }
}
