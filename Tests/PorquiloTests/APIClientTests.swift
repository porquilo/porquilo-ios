import XCTest
@testable import Porquilo

final class APIClientTests: XCTestCase {
    func testServerErrorDecoding() {
        let json = """
        {"error": {"code": "barcode_not_found", "message": "Not found", "details": {}}}
        """
        let data = Data(json.utf8)

        let error = APIClient.serverError(from: data)

        switch error {
        case .serverError(let code, let message):
            XCTAssertEqual(code, "barcode_not_found")
            XCTAssertEqual(message, "Not found")
        default:
            XCTFail("Expected .serverError, got \(error)")
        }
    }

    func testNotFoundIsEquatable() {
        XCTAssertEqual(PorquiloAPIError.notFound, PorquiloAPIError.notFound)
        XCTAssertNotEqual(PorquiloAPIError.notFound, PorquiloAPIError.unauthorized)
    }

    func testDiaryEntryScaleSourceIsNotEstimated() throws {
        let json = """
        {
            "date": "2026-06-24",
            "macro_total": {"calories": 100, "protein_g": 1, "carbs_g": 1, "fat_g": 1},
            "entries": [
                {
                    "id": "\(UUID().uuidString)",
                    "food_id": "\(UUID().uuidString)",
                    "food_name": "Chicken",
                    "quantity_g": 100,
                    "calories": 100,
                    "protein_g": 1,
                    "carbs_g": 1,
                    "fat_g": 1,
                    "weight_source": "scale",
                    "eaten_at": "2026-06-24T07:30:00Z",
                    "meal_slot": "breakfast"
                }
            ]
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(DiaryResponse.self, from: Data(json.utf8))
        let diaryDay = dto.toDiaryDay(on: Date())

        let breakfast = diaryDay.meals.first { $0.slot == .breakfast }
        XCTAssertEqual(breakfast?.entries.first?.isEstimated, false)
    }

    func testDiaryEntryNonScaleSourceIsEstimated() throws {
        let json = """
        {
            "date": "2026-06-24",
            "macro_total": {"calories": 100, "protein_g": 1, "carbs_g": 1, "fat_g": 1},
            "entries": [
                {
                    "id": "\(UUID().uuidString)",
                    "food_id": "\(UUID().uuidString)",
                    "food_name": "Chicken",
                    "quantity_g": 100,
                    "calories": 100,
                    "protein_g": 1,
                    "carbs_g": 1,
                    "fat_g": 1,
                    "weight_source": "quick_log",
                    "eaten_at": "2026-06-24T07:30:00Z",
                    "meal_slot": "breakfast"
                }
            ]
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(DiaryResponse.self, from: Data(json.utf8))
        let diaryDay = dto.toDiaryDay(on: Date())

        let breakfast = diaryDay.meals.first { $0.slot == .breakfast }
        XCTAssertEqual(breakfast?.entries.first?.isEstimated, true)
    }

    func testFetchDiary404ReturnsEmptyDiaryDay() async throws {
        URLProtocol.registerClass(StubURLProtocol.self)
        defer { URLProtocol.unregisterClass(StubURLProtocol.self) }

        StubURLProtocol.stubStatusCode = 404
        StubURLProtocol.stubData = Data()

        let previousServerURL = UserDefaults.standard.string(forKey: AppConstants.serverURLKey)
        UserDefaults.standard.set("https://example.invalid", forKey: AppConstants.serverURLKey)
        defer {
            if let previousServerURL {
                UserDefaults.standard.set(previousServerURL, forKey: AppConstants.serverURLKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppConstants.serverURLKey)
            }
        }

        let diaryDay = try await APIClient.shared.fetchDiary(for: Date())

        XCTAssertEqual(diaryDay.macroTotal.calories, 0)
        XCTAssertEqual(diaryDay.meals.count, MealSlot.allCases.count)
        XCTAssertTrue(diaryDay.meals.allSatisfy { $0.entries.isEmpty })
    }
}

private final class StubURLProtocol: URLProtocol {
    static var stubStatusCode = 200
    static var stubData = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.stubStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.stubData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
