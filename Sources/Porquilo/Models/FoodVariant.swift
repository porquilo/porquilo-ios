import Foundation

/// A named serving variant for a food (e.g. "1 slice", "1 tbsp"), as returned
/// alongside search results from `GET /api/foods`. `name` is nil for unnamed
/// variants, which callers should skip when building a serving-mode selector.
struct FoodVariant: Decodable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String?
    let amount: Double?
    let unit: String
}
