import Foundation

/// A named serving variant for a food (e.g. "1 slice", "1 tbsp"), as returned
/// alongside search results from `GET /api/foods`. `name` is nil for unnamed
/// variants, which callers should skip when building a serving-mode selector.
///
/// Two different server response shapes decode into this same type:
/// `FoodVariantRead` (search results) includes `id`; `VariantOut` (used by
/// `FoodOut` — barcode lookup, `POST /api/foods`, patch/get-by-id) does not.
/// A custom decoder fills in a fresh `id` when the key is absent, since
/// nothing in the app round-trips a variant's id back to the server. `amount`
/// is a `Decimal` on the server, serialized as a JSON string (e.g.
/// `"400.0000000000"`) — same convention as nutrient values — but a raw JSON
/// number is tolerated too.
struct FoodVariant: Decodable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String?
    let amount: Double?
    let unit: String

    private enum CodingKeys: String, CodingKey {
        case id, name, amount, unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name)
        unit = try container.decode(String.self, forKey: .unit)
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: .amount) {
            amount = Double(stringValue)
        } else {
            amount = try container.decodeIfPresent(Double.self, forKey: .amount)
        }
    }
}
