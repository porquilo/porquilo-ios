import Foundation

/// The server sends `eaten_at` in several shapes depending on the path:
/// Pydantic serializes timezone-aware `datetime` fields with microsecond
/// fractional seconds and an offset (`2026-06-24T07:30:00.123456+00:00`),
/// but SQLite drops tzinfo on round-trip, so `GET /api/diary/{date}` comes
/// back with no offset at all (`2026-06-29T09:29:00`). Entries are always
/// POSTed in UTC (`CreateLogEntryBody` uses `ISO8601DateFormatter`'s UTC
/// default), so a naive string is treated as UTC.
///
/// A free function (rather than a type method) so it satisfies `@Sendable`
/// for `JSONDecoder.DateDecodingStrategy.custom` without a conversion warning.
@Sendable func decodeServerDate(from decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)

    let withFractional = ISO8601DateFormatter()
    withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = withFractional.date(from: string) {
        return date
    }

    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    if let date = plain.date(from: string) {
        return date
    }

    let naive = DateFormatter()
    naive.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    naive.timeZone = TimeZone(identifier: "UTC")
    if let date = naive.date(from: string) {
        return date
    }

    throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Expected date string to be ISO8601-formatted: \(string)"
    )
}

enum PorquiloAPIError: Error, LocalizedError {
    case serverError(code: String, message: String)
    case networkError(Error)
    case decodingError(Error)
    case noServerConfigured
    case unauthorized
    case notFound

    var errorDescription: String? {
        switch self {
        case .serverError(_, let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return error.localizedDescription
        case .noServerConfigured:
            return "No server configured."
        case .unauthorized:
            return "Unauthorized."
        case .notFound:
            return "Not found."
        }
    }
}

extension PorquiloAPIError: Equatable {
    static func == (lhs: PorquiloAPIError, rhs: PorquiloAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.serverError(let lCode, let lMessage), .serverError(let rCode, let rMessage)):
            return lCode == rCode && lMessage == rMessage
        case (.networkError, .networkError),
             (.decodingError, .decodingError),
             (.noServerConfigured, .noServerConfigured),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound):
            return true
        default:
            return false
        }
    }
}

/// Mirrors `RecentFoodSuggestion` from `GET /api/foods/suggestions`.
struct RecentFoodItem: Decodable {
    let foodId: UUID
    let foodName: String
    let sourceKey: String
    let sourceDisplay: String
    let caloriesPer100g: Double
    let lastLoggedAt: Date

    enum CodingKeys: String, CodingKey {
        case foodId = "food_id"
        case foodName = "food_name"
        case sourceKey = "source_key"
        case sourceDisplay = "source_display"
        case caloriesPer100g = "calories_per_100g"
        case lastLoggedAt = "last_logged_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foodId = try container.decode(UUID.self, forKey: .foodId)
        foodName = try container.decode(String.self, forKey: .foodName)
        sourceKey = try container.decode(String.self, forKey: .sourceKey)
        sourceDisplay = try container.decode(String.self, forKey: .sourceDisplay)
        caloriesPer100g = try container.decode(Double.self, forKey: .caloriesPer100g)
        lastLoggedAt = try decodeServerDate(from: container.superDecoder(forKey: .lastLoggedAt))
    }
}

/// Mirrors `FrequentFoodSuggestion` from `GET /api/foods/suggestions`.
struct FrequentFoodItem: Decodable {
    let foodId: UUID
    let foodName: String
    let sourceKey: String
    let sourceDisplay: String
    let caloriesPer100g: Double
    let logCount: Int

    enum CodingKeys: String, CodingKey {
        case foodId = "food_id"
        case foodName = "food_name"
        case sourceKey = "source_key"
        case sourceDisplay = "source_display"
        case caloriesPer100g = "calories_per_100g"
        case logCount = "log_count"
    }
}

struct FoodSuggestionsResponse: Decodable {
    let recent: [RecentFoodItem]
    let frequent: [FrequentFoodItem]
}

@Observable
final class APIClient {
    static let shared = APIClient()

    private var baseURL: URL? {
        guard let raw = UserDefaults.standard.string(forKey: AppConstants.serverURLKey),
              let url = URL(string: raw) else { return nil }
        return url
    }

    private struct ErrorEnvelope: Decodable {
        struct Inner: Decodable {
            let code: String
            let message: String
        }
        let error: Inner
    }

    private struct LoginRequestBody: Encodable {
        let username: String
        let password: String
    }

    private struct PairingExchangeBody: Encodable {
        let code: String
    }

    private struct LoginResponse: Decodable {
        let token: String
        let user: User
    }

    private struct VersionResponse: Decodable {
        let version: String
    }

    /// Mirrors `FoodRead` from `GET /api/foods` — nutrients arrive as a dict.
    /// Pydantic serializes `Decimal` fields as JSON strings (e.g. `"48.4000000000"`),
    /// not numbers, so the dict values must be decoded as `String` and parsed.
    private struct FoodReadDTO: Decodable {
        let id: UUID
        let name: String
        let brand: String?
        let displayName: String?
        let source: String
        let nutrients: [String: String]

        enum CodingKeys: String, CodingKey {
            case id, name, brand
            case displayName = "display_name"
            case source, nutrients
        }
    }

    private struct FoodPageResponse: Decodable {
        let items: [FoodReadDTO]
        let total: Int
    }

    /// `value_per_100` is a `Decimal` on the server, serialized as a JSON string.
    private struct NutrientOutDTO: Decodable {
        let nutrientKey: String
        let valuePer100: String

        enum CodingKeys: String, CodingKey {
            case nutrientKey = "nutrient_key"
            case valuePer100 = "value_per_100"
        }
    }

    /// Mirrors `FoodOut` from `GET /api/foods/lookup/barcode/{upc}` — nutrients
    /// arrive as a list here, unlike the dict shape `FoodRead` uses for search.
    private struct FoodOutDTO: Decodable {
        let id: UUID
        let name: String
        let brand: String?
        let displayName: String?
        let source: String
        let nutrients: [NutrientOutDTO]

        enum CodingKeys: String, CodingKey {
            case id, name, brand
            case displayName = "display_name"
            case source, nutrients
        }
    }

    private struct MealDTO: Decodable {
        let id: UUID
        let name: String
        let sortOrder: Int
        let isDefault: Bool

        enum CodingKeys: String, CodingKey {
            case id, name
            case sortOrder = "sort_order"
            case isDefault = "is_default"
        }
    }

    private struct CreateLogEntryBody: Encodable {
        let foodId: UUID
        let mealId: UUID
        let weightG: Double
        let eatenAt: Date
        let weightSource: String
        let inputMethod: String

        enum CodingKeys: String, CodingKey {
            case foodId = "food_id"
            case mealId = "meal_id"
            case weightG = "weight_g"
            case eatenAt = "eaten_at"
            case weightSource = "weight_source"
            case inputMethod = "input_method"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(foodId, forKey: .foodId)
            try container.encode(mealId, forKey: .mealId)
            try container.encode(weightG, forKey: .weightG)
            try container.encode(ISO8601DateFormatter().string(from: eatenAt), forKey: .eatenAt)
            try container.encode(weightSource, forKey: .weightSource)
            try container.encode(inputMethod, forKey: .inputMethod)
        }
    }

    /// Mirrors `EntryOut` from `POST /api/entries`. `value` is a `Decimal` on the
    /// server, serialized as a JSON string.
    struct LoggedEntry: Decodable {
        struct NutrientValue: Decodable {
            let value: String
            let coverage: String
        }

        let id: UUID
        let nutrients: [String: NutrientValue]
    }

    private static func displaySourceName(_ source: String) -> String {
        switch source {
        case "usda": return "USDA"
        case "open_food_facts": return "Barcode"
        case "custom": return "Pantry"
        default: return source.capitalized
        }
    }

    private static func searchResult(from dto: FoodReadDTO, isTopMatch: Bool) -> FoodSearchResult {
        FoodSearchResult(
            id: dto.id,
            name: dto.displayName ?? dto.name,
            sourceName: Self.displaySourceName(dto.source),
            subtitle: dto.brand ?? Self.displaySourceName(dto.source),
            nutrientsPer100g: dto.nutrients.compactMapValues(Double.init),
            isTopMatch: isTopMatch
        )
    }

    private static func searchResult(from dto: FoodOutDTO) -> FoodSearchResult {
        let nutrients = Dictionary(
            uniqueKeysWithValues: dto.nutrients.compactMap { nutrient -> (String, Double)? in
                guard let value = Double(nutrient.valuePer100) else { return nil }
                return (nutrient.nutrientKey, value)
            }
        )
        return FoodSearchResult(
            id: dto.id,
            name: dto.displayName ?? dto.name,
            sourceName: Self.displaySourceName(dto.source),
            subtitle: dto.brand ?? Self.displaySourceName(dto.source),
            nutrientsPer100g: nutrients,
            isTopMatch: false
        )
    }

    static func serverError(from data: Data) -> PorquiloAPIError {
        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
            return .serverError(code: envelope.error.code, message: envelope.error.message)
        }
        return .networkError(URLError(.badServerResponse))
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let baseURL else { throw PorquiloAPIError.noServerConfigured }
        guard let url = Self.buildURL(baseURL: baseURL, path: path) else {
            throw PorquiloAPIError.noServerConfigured
        }
        let request = Self.buildRequest(
            url: url,
            method: method,
            body: body,
            authToken: KeychainService.load()
        )
        return try await Self.perform(request)
    }

    /// `appendingPathComponent` percent-encodes the entire string it's given as a
    /// single path segment — including a literal `?`, turning `api/foods?q=x` into
    /// the path `api/foods%3Fq=x` instead of a path with a query string. Split the
    /// query off before appending so callers can keep passing `"path?query"`.
    private static func buildURL(baseURL: URL, path: String) -> URL? {
        let parts = path.split(separator: "?", maxSplits: 1)
        let url = baseURL.appendingPathComponent(String(parts[0]))
        guard parts.count > 1 else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = String(parts[1])
        return components?.url ?? url
    }

    /// Builds its request from the passed-in `serverURL`, not the stored `baseURL` —
    /// at call time the server hasn't been configured yet (the user is mid-login).
    func login(serverURL: URL, username: String, password: String) async throws -> (token: String, user: User) {
        let request = Self.buildRequest(
            url: serverURL.appendingPathComponent("api/auth/token"),
            method: "POST",
            body: LoginRequestBody(username: username, password: password),
            authToken: nil
        )
        let response: LoginResponse = try await Self.perform(request)
        return (response.token, response.user)
    }

    /// Builds its request from the scanned `serverURL`, not the stored `baseURL`.
    func exchangePairingCode(_ code: String, serverURL: URL) async throws -> (token: String, user: User) {
        let request = Self.buildRequest(
            url: serverURL.appendingPathComponent("api/auth/pairing/exchange"),
            method: "POST",
            body: PairingExchangeBody(code: code),
            authToken: nil
        )
        let response: LoginResponse = try await Self.perform(request)
        return (response.token, response.user)
    }

    /// `GET /api/foods` always returns `{"items": [], "total": 0}` for no matches —
    /// there's no 404 case to special-case here.
    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let response: FoodPageResponse = try await request("api/foods?q=\(encodedQuery)")
        return response.items.enumerated().map { index, dto in
            Self.searchResult(from: dto, isTopMatch: index == 0)
        }
    }

    func lookupBarcode(_ barcode: String) async throws -> FoodSearchResult {
        let dto: FoodOutDTO = try await request("api/foods/lookup/barcode/\(barcode)")
        return Self.searchResult(from: dto)
    }

    func fetchMeals() async throws -> [Meal] {
        let dtos: [MealDTO] = try await request("api/meals")
        return dtos.map { Meal(id: $0.id, name: $0.name, sortOrder: $0.sortOrder, isDefault: $0.isDefault) }
    }

    @discardableResult
    func createLogEntry(
        foodId: UUID,
        mealId: UUID,
        weightG: Double,
        eatenAt: Date,
        weightSource: String,
        inputMethod: String
    ) async throws -> LoggedEntry {
        let body = CreateLogEntryBody(
            foodId: foodId,
            mealId: mealId,
            weightG: weightG,
            eatenAt: eatenAt,
            weightSource: weightSource,
            inputMethod: inputMethod
        )
        return try await request("api/entries", method: "POST", body: body)
    }

    /// `GET /api/diary/{date}` — `date` is formatted "YYYY-MM-DD" in the user's
    /// current calendar. 404 means an empty diary day, not an error.
    func fetchDiary(for date: Date) async throws -> DiaryDay {
        guard let baseURL else { throw PorquiloAPIError.noServerConfigured }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = .current
        formatter.timeZone = .current
        let dateString = formatter.string(from: date)

        let request = Self.buildRequest(
            url: baseURL.appendingPathComponent("api/diary/\(dateString)"),
            method: "GET",
            body: nil,
            authToken: KeychainService.load()
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PorquiloAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PorquiloAPIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw PorquiloAPIError.unauthorized
        }

        if httpResponse.statusCode == 404 {
            return DiaryDay(
                date: date,
                macroTotal: MacroTotal(calories: 0, proteinG: 0, carbsG: 0, fatG: 0, isEstimated: false),
                meals: []
            )
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            throw Self.serverError(from: data)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(decodeServerDate)
        do {
            let dto = try decoder.decode(DiaryResponse.self, from: data)
            return dto.toDiaryDay(on: date)
        } catch {
            throw PorquiloAPIError.decodingError(error)
        }
    }

    /// `GET /api/foods/suggestions` — both arrays may be empty; never throws on empty.
    func fetchFoodSuggestions() async throws -> FoodSuggestionsResponse {
        try await request("api/foods/suggestions")
    }

    func fetchServerVersion() async throws -> String {
        guard let baseURL else { throw PorquiloAPIError.noServerConfigured }
        let request = Self.buildRequest(
            url: baseURL.appendingPathComponent("api/version"),
            method: "GET",
            body: nil,
            authToken: nil
        )
        let response: VersionResponse = try await Self.perform(request)
        return response.version
    }

    private static func buildRequest(
        url: URL,
        method: String,
        body: (any Encodable)?,
        authToken: String?
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(AnyEncodable(body))
        }

        return request
    }

    private static func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PorquiloAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PorquiloAPIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw PorquiloAPIError.unauthorized
        }

        if httpResponse.statusCode == 404 {
            throw PorquiloAPIError.notFound
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            throw serverError(from: data)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw PorquiloAPIError.decodingError(error)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ encodable: any Encodable) {
        self.encodeClosure = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
