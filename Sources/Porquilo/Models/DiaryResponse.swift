import Foundation

/// Mirrors `GET /api/diary/{date}` exactly. Mapping to the view-layer `DiaryDay`
/// lives in the extension below, not in `DiaryModels.swift`.
struct DiaryResponse: Decodable {
    var date: String
    var macroTotal: MacroTotalResponse
    var entries: [DiaryEntryResponse]

    struct MacroTotalResponse: Decodable {
        var calories: Double
        var proteinG: Double
        var carbsG: Double
        var fatG: Double
    }

    struct DiaryEntryResponse: Decodable {
        var id: UUID
        var foodId: UUID
        var foodName: String
        var quantityG: Double
        var calories: Double
        var proteinG: Double
        var carbsG: Double
        var fatG: Double
        var weightSource: String
        var eatenAt: Date
        var mealSlot: String
    }
}

extension DiaryResponse {
    func toDiaryDay(on date: Date) -> DiaryDay {
        let entriesBySlot = Dictionary(grouping: entries, by: \.mealSlot)

        let meals = MealSlot.allCases.map { slot -> MealSection in
            let slotEntries = (entriesBySlot[slot.wireValue] ?? []).map { entry -> DiaryLogEntry in
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm"
                formatter.timeZone = .current

                return DiaryLogEntry(
                    id: entry.id,
                    foodName: entry.foodName,
                    timeString: formatter.string(from: entry.eatenAt),
                    weightG: entry.quantityG,
                    calories: entry.calories,
                    isEstimated: entry.weightSource != "scale"
                )
            }
            return MealSection(slot: slot, entries: slotEntries)
        }

        return DiaryDay(
            date: date,
            macroTotal: MacroTotal(
                calories: macroTotal.calories,
                proteinG: macroTotal.proteinG,
                carbsG: macroTotal.carbsG,
                fatG: macroTotal.fatG,
                isEstimated: entries.contains { $0.weightSource != "scale" }
            ),
            meals: meals
        )
    }
}
