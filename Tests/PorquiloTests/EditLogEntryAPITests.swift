import XCTest
@testable import Porquilo

final class EditLogEntryAPITests: XCTestCase {
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

    func testUpdateLogEntryPatchesExpectedQuantityAndTime() async throws {
        var capturedRequest: URLRequest?
        var capturedBody: [String: Any]?

        let entryId = UUID()
        let eatenAt = ISO8601DateFormatter().date(from: "2026-06-24T19:12:00Z")!

        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            if let bodyData = request.bodyData,
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                capturedBody = json
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await APIClient.shared.updateLogEntry(id: entryId, quantityG: 150, eatenAt: eatenAt, weightSource: nil)

        XCTAssertEqual(capturedRequest?.httpMethod, "PATCH")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/entries/\(entryId.uuidString)")
        XCTAssertEqual(capturedBody?["weight_g"] as? Double, 150)
        XCTAssertEqual(capturedBody?["eaten_at"] as? String, "2026-06-24T19:12:00Z")
        XCTAssertNil(capturedBody?["weight_source"])
    }

    func testUpdateLogEntrySendsWeightSourceWhenDemoting() async throws {
        var capturedBody: [String: Any]?

        StubURLProtocol.requestHandler = { request in
            if let bodyData = request.bodyData,
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                capturedBody = json
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await APIClient.shared.updateLogEntry(id: UUID(), quantityG: 200, eatenAt: Date(), weightSource: "quick_search")

        XCTAssertEqual(capturedBody?["weight_source"] as? String, "quick_search")
    }

    func testUpdateLogEntryOmitsWeightSourceKeyWhenNil() async throws {
        var capturedBody: [String: Any]?

        StubURLProtocol.requestHandler = { request in
            if let bodyData = request.bodyData,
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                capturedBody = json
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await APIClient.shared.updateLogEntry(id: UUID(), quantityG: 200, eatenAt: Date(), weightSource: nil)

        XCTAssertFalse(capturedBody?.keys.contains("weight_source") ?? true)
    }

    func testDeleteLogEntrySendsDeleteToEntryScopedRoute() async throws {
        var capturedRequest: URLRequest?
        let entryId = UUID()

        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await APIClient.shared.deleteLogEntry(id: entryId)

        XCTAssertEqual(capturedRequest?.httpMethod, "DELETE")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/entries/\(entryId.uuidString)")
    }

    func testDeleteLogEntryThrowsOnServerError() async {
        StubURLProtocol.requestHandler = { request in
            let json = """
            {"error": {"code": "not_found", "message": "Entry not found.", "details": {}}}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        do {
            try await APIClient.shared.deleteLogEntry(id: UUID())
            XCTFail("Expected deleteLogEntry to throw")
        } catch PorquiloAPIError.notFound {
            // Expected: performVoid special-cases 404 before decoding the error envelope.
        } catch {
            XCTFail("Expected notFound, got \(error)")
        }
    }

    func testFetchLogEntryDecodesWeightSourceAndQuantity() async throws {
        let entryId = UUID()

        StubURLProtocol.requestHandler = { request in
            let json = """
            {
                "id": "\(entryId.uuidString)",
                "food_id": "\(UUID().uuidString)",
                "food_name": "Chicken",
                "meal_id": "\(UUID().uuidString)",
                "eaten_at": "2026-06-24T07:30:00Z",
                "logged_at": "2026-06-24T07:31:00Z",
                "weight_g": "150.0000000000",
                "weight_source": "scale",
                "weight_confidence": "measured",
                "input_method": "manual",
                "nutrients": {}
            }
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let detail = try await APIClient.shared.fetchLogEntry(id: entryId)

        XCTAssertEqual(detail.quantityG, 150)
        XCTAssertEqual(detail.weightSource, "scale")
        XCTAssertEqual(detail.eatenAt.timeIntervalSince1970, 1782286200, accuracy: 0.001)
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
