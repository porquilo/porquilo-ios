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

    func testDiaryEntryMeasuredConfidenceIsNotEstimated() throws {
        let json = """
        {
            "date": "2026-06-24",
            "day_totals": {"calories_kcal": "100", "protein_g": "1", "carbs_g": "1", "fat_g": "1"},
            "has_estimated_entries": false,
            "meals": [
                {
                    "meal_id": "\(UUID().uuidString)",
                    "meal_name": "Breakfast",
                    "is_skipped": false,
                    "meal_totals": {"calories_kcal": "100"},
                    "entries": [
                        {
                            "id": "\(UUID().uuidString)",
                            "food_name": "Chicken",
                            "weight_g": "100",
                            "weight_confidence": "measured",
                            "input_method": "manual",
                            "eaten_at": "2026-06-24T07:30:00Z",
                            "nutrients": {"calories_kcal": {"value": "100", "coverage": "full"}}
                        }
                    ]
                }
            ]
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(APIClient.decodeServerDate)
        let dto = try decoder.decode(DiaryResponse.self, from: Data(json.utf8))
        let diaryDay = dto.toDiaryDay(on: Date())

        let breakfast = diaryDay.meals.first { $0.name == "Breakfast" }
        XCTAssertEqual(breakfast?.entries.first?.isEstimated, false)
    }

    func testDiaryEntryEstimatedConfidenceIsEstimated() throws {
        let json = """
        {
            "date": "2026-06-24",
            "day_totals": {"calories_kcal": "100", "protein_g": "1", "carbs_g": "1", "fat_g": "1"},
            "has_estimated_entries": true,
            "meals": [
                {
                    "meal_id": "\(UUID().uuidString)",
                    "meal_name": "Breakfast",
                    "is_skipped": false,
                    "meal_totals": {"calories_kcal": "100"},
                    "entries": [
                        {
                            "id": "\(UUID().uuidString)",
                            "food_name": "Chicken",
                            "weight_g": "100",
                            "weight_confidence": "estimated",
                            "input_method": "quick_log",
                            "eaten_at": "2026-06-24T07:30:00Z",
                            "nutrients": {"calories_kcal": {"value": "100", "coverage": "full"}}
                        }
                    ]
                }
            ]
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(APIClient.decodeServerDate)
        let dto = try decoder.decode(DiaryResponse.self, from: Data(json.utf8))
        let diaryDay = dto.toDiaryDay(on: Date())

        let breakfast = diaryDay.meals.first { $0.name == "Breakfast" }
        XCTAssertEqual(breakfast?.entries.first?.isEstimated, true)
    }

    func testDecodeServerDateAcceptsFractionalSeconds() throws {
        let json = """
        {
            "date": "2026-06-24",
            "day_totals": {},
            "has_estimated_entries": false,
            "meals": [
                {
                    "meal_id": "\(UUID().uuidString)",
                    "meal_name": "Breakfast",
                    "is_skipped": false,
                    "meal_totals": {},
                    "entries": [
                        {
                            "id": "\(UUID().uuidString)",
                            "food_name": "Chicken",
                            "weight_g": "100",
                            "weight_confidence": "measured",
                            "input_method": "manual",
                            "eaten_at": "2026-06-24T07:30:00.123456+00:00",
                            "nutrients": {}
                        }
                    ]
                }
            ]
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(APIClient.decodeServerDate)
        let dto = try decoder.decode(DiaryResponse.self, from: Data(json.utf8))

        let eatenAt = try XCTUnwrap(dto.meals.first?.entries.first?.eatenAt)
        XCTAssertEqual(eatenAt.timeIntervalSince1970, 1782286200.123456, accuracy: 0.001)
    }

    func testDecodeServerDateAcceptsNaiveTimestamp() throws {
        let json = """
        {
            "date": "2026-06-24",
            "day_totals": {},
            "has_estimated_entries": false,
            "meals": [
                {
                    "meal_id": "\(UUID().uuidString)",
                    "meal_name": "Breakfast",
                    "is_skipped": false,
                    "meal_totals": {},
                    "entries": [
                        {
                            "id": "\(UUID().uuidString)",
                            "food_name": "Chicken",
                            "weight_g": "100",
                            "weight_confidence": "measured",
                            "input_method": "manual",
                            "eaten_at": "2026-06-29T09:29:00",
                            "nutrients": {}
                        }
                    ]
                }
            ]
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(APIClient.decodeServerDate)
        let dto = try decoder.decode(DiaryResponse.self, from: Data(json.utf8))

        let eatenAt = try XCTUnwrap(dto.meals.first?.entries.first?.eatenAt)
        XCTAssertEqual(eatenAt.timeIntervalSince1970, 1782725340, accuracy: 0.001)
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
        XCTAssertTrue(diaryDay.meals.isEmpty)
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
