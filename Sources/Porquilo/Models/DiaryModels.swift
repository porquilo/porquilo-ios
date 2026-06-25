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
}

struct MealSection: Identifiable {
    var slot: MealSlot
    var entries: [DiaryLogEntry]

    var id: MealSlot { slot }
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
            MealSection(slot: .breakfast, entries: [
                DiaryLogEntry(id: UUID(), foodName: "Overnight oats", timeString: "7:30",
                              weightG: 385, calories: 420, isEstimated: true),
            ]),
            MealSection(slot: .lunch, entries: [
                DiaryLogEntry(id: UUID(), foodName: "Chicken salad wrap", timeString: "12:45",
                              weightG: 280, calories: 410, isEstimated: true),
            ]),
            MealSection(slot: .dinner, entries: []),
        ]
    )
}
