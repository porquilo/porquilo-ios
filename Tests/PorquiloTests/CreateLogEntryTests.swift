import XCTest
@testable import Porquilo

final class CreateLogEntryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.set("https://nutrition.test", forKey: AppConstants.serverURLKey)
        URLProtocol.registerClass(StubURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        UserDefaults.standard.removeObject(forKey: AppConstants.serverURLKey)
        StubURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testCreateLogEntryPostsExpectedBodyAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        var capturedBody: [String: Any]?

        let entryId = UUID()

        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            if let bodyData = request.bodyData,
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                capturedBody = json
            }

            let json = """
            {"id": "\(entryId.uuidString)", "nutrients": {"calories_kcal": {"value": "420.0000000000", "coverage": "full"}}}
            """
            let data = Data(json.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let foodId = UUID()
        let mealId = UUID()
        let eatenAt = ISO8601DateFormatter().date(from: "2026-06-24T19:12:00Z")!

        let entry = try await APIClient.shared.createLogEntry(
            foodId: foodId,
            mealId: mealId,
            weightG: 240.0,
            eatenAt: eatenAt,
            weightSource: "estimated",
            inputMethod: "quick_search"
        )

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/entries")
        XCTAssertEqual(capturedBody?["food_id"] as? String, foodId.uuidString)
        XCTAssertEqual(capturedBody?["meal_id"] as? String, mealId.uuidString)
        XCTAssertEqual(capturedBody?["weight_g"] as? Double, 240.0)
        XCTAssertEqual(capturedBody?["weight_source"] as? String, "estimated")
        XCTAssertEqual(capturedBody?["input_method"] as? String, "quick_search")
        XCTAssertEqual(capturedBody?["eaten_at"] as? String, "2026-06-24T19:12:00Z")

        XCTAssertEqual(entry.id, entryId)
        XCTAssertEqual(entry.nutrients["calories_kcal"]?.value, "420.0000000000")
        XCTAssertEqual(entry.nutrients["calories_kcal"]?.coverage, "full")
    }

    func testCreateLogEntryThrowsOnServerError() async {
        StubURLProtocol.requestHandler = { request in
            let json = """
            {"error": {"code": "invalid_quantity", "message": "Quantity must be positive.", "details": {}}}
            """
            let data = Data(json.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        do {
            _ = try await APIClient.shared.createLogEntry(
                foodId: UUID(),
                mealId: UUID(),
                weightG: -5,
                eatenAt: Date(),
                weightSource: "estimated",
                inputMethod: "quick_search"
            )
            XCTFail("Expected createLogEntry to throw")
        } catch PorquiloAPIError.serverError(let code, let message) {
            XCTAssertEqual(code, "invalid_quantity")
            XCTAssertEqual(message, "Quantity must be positive.")
        } catch {
            XCTFail("Expected serverError, got \(error)")
        }
    }
}

private final class StubURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLRequest {
    var bodyData: Data? {
        httpBody ?? httpBodyStream.flatMap { stream in
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                } else {
                    break
                }
            }
            return data
        }
    }
}
