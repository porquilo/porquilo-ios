import Foundation

struct MacroTotal {
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var isEstimated: Bool
}

struct DiaryLogEntry: Identifiable {
    var id: UUID
    var foodName: String
    var timeString: String
    var weightG: Double?
    var calories: Double
    var isEstimated: Bool
}

enum MealSlot: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    static func inferred(from date: Date) -> MealSlot {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<20: return .dinner
        default: return .snack
        }
    }
}

/// One real per-household `Meal` row and its entries for the day. Meal names
/// are household-defined (e.g. "Second Breakfast"), not limited to the four
/// `MealSlot` cases — `MealSlot` is only used for inferring a sensible
/// default meal by time of day, not for rendering the diary.
struct MealSection: Identifiable {
    var id: UUID
    var name: String
    var entries: [DiaryLogEntry]

    var isEstimated: Bool { entries.contains { $0.isEstimated } }
    var totalCalories: Double { entries.reduce(0) { $0 + $1.calories } }
}

struct DiaryDay {
    var date: Date
    var macroTotal: MacroTotal
    var meals: [MealSection]

    static let sample = DiaryDay(
        date: Date(),
        macroTotal: MacroTotal(calories: 1420, proteinG: 72, carbsG: 158, fatG: 46, isEstimated: true),
        meals: [
            MealSection(id: UUID(), name: "Breakfast", entries: [
                DiaryLogEntry(id: UUID(), foodName: "Overnight oats", timeString: "7:30",
                              weightG: 385, calories: 420, isEstimated: true),
            ]),
            MealSection(id: UUID(), name: "Lunch", entries: [
                DiaryLogEntry(id: UUID(), foodName: "Chicken salad wrap", timeString: "12:45",
                              weightG: 280, calories: 410, isEstimated: true),
            ]),
            MealSection(id: UUID(), name: "Dinner", entries: []),
        ]
    )
}
