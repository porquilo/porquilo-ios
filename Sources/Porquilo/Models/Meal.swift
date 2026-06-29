import Foundation

struct Meal: Identifiable, Equatable, Decodable {
    var id: UUID
    var name: String
    var sortOrder: Int
    var isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, name
        case sortOrder = "sort_order"
        case isDefault = "is_default"
    }
}

extension Meal {
    /// Picks the meal whose name matches the inferred time-of-day slot (e.g. "Breakfast"),
    /// falling back to the household's first meal by sort order. Meals are real per-household
    /// records, not a fixed enum, so this is a best-effort default rather than a guarantee.
    static func inferredDefault(from meals: [Meal], at date: Date) -> Meal? {
        let slotName = MealSlot.inferred(from: date).rawValue
        if let match = meals.first(where: { $0.name.caseInsensitiveCompare(slotName) == .orderedSame }) {
            return match
        }
        return meals.sorted(by: { $0.sortOrder < $1.sortOrder }).first
    }
}
