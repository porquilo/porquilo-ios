import Foundation

/// Mirrors `GET /api/diary/{date}` exactly (see `DiaryResponse` in
/// `porquilo-web/server/src/porquilo/routers/diary.py`). Meal identity is
/// structural — entries are nested under their `MealResponse`, not tagged
/// with a slot field of their own. Nutrient totals are a flat
/// `[nutrientKey: Decimal]` map, not fixed fields; the keys this app reads
/// are `calories_kcal`, `protein_g`, `carbs_g`, `fat_g` (from
/// `nutrient_definitions` seed data). Mapping to the view-layer `DiaryDay`
/// lives in the extension below, not in `DiaryModels.swift`.
struct DiaryResponse: Decodable {
    var date: String
    var meals: [MealResponse]
    var dayTotals: [String: String]
    var hasEstimatedEntries: Bool

    /// `Decimal` fields are serialized as JSON strings by Pydantic, not numbers
    /// (same convention as `FoodReadDTO`/`NutrientOutDTO` in `APIClient`).
    struct NutrientValue: Decodable {
        var value: String
        var coverage: String
    }

    struct DiaryEntryResponse: Decodable {
        var id: UUID
        var foodName: String
        var weightG: String?
        var weightConfidence: String
        var inputMethod: String
        var eatenAt: Date
        var nutrients: [String: NutrientValue]
    }

    struct MealResponse: Decodable {
        var mealId: UUID
        var mealName: String
        var isSkipped: Bool
        var entries: [DiaryEntryResponse]
        var mealTotals: [String: String]
    }
}

extension DiaryResponse {
    func toDiaryDay(on date: Date) -> DiaryDay {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm"
        timeFormatter.timeZone = .current

        let sections = meals.map { meal -> MealSection in
            let entries = meal.entries.map { entry -> DiaryLogEntry in
                DiaryLogEntry(
                    id: entry.id,
                    foodName: entry.foodName,
                    timeString: timeFormatter.string(from: entry.eatenAt),
                    weightG: entry.weightG.flatMap(Double.init),
                    calories: entry.nutrients["calories_kcal"].flatMap { Double($0.value) } ?? 0,
                    isEstimated: entry.weightConfidence != "measured"
                )
            }
            return MealSection(id: meal.mealId, name: meal.mealName, entries: entries)
        }

        return DiaryDay(
            date: date,
            macroTotal: MacroTotal(
                calories: dayTotals["calories_kcal"].flatMap(Double.init) ?? 0,
                proteinG: dayTotals["protein_g"].flatMap(Double.init) ?? 0,
                carbsG: dayTotals["carbs_g"].flatMap(Double.init) ?? 0,
                fatG: dayTotals["fat_g"].flatMap(Double.init) ?? 0,
                isEstimated: hasEstimatedEntries
            ),
            meals: sections
        )
    }
}
