import XCTest
@testable import Porquilo

final class CreateFoodAPITests: XCTestCase {
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

    func testCreateFoodPostsExpectedBodyAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        var capturedBody: [String: Any]?

        let foodId = UUID()

        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            if let bodyData = request.bodyData,
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                capturedBody = json
            }

            let json = """
            {
                "id": "\(foodId.uuidString)",
                "name": "Banana, raw",
                "brand": null,
                "display_name": null,
                "source": "custom",
                "default_unit": "g",
                "nutrients": [{"nutrient_key": "calories_kcal", "value_per_100": "89.0000000000"}],
                "variants": []
            }
            """
            let data = Data(json.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result = try await APIClient.shared.createFood(
            name: "Banana, raw",
            brand: nil,
            barcode: nil,
            defaultUnit: "g",
            nutrients: [("calories_kcal", 89), ("protein_g", 1.1)],
            variants: []
        )

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/foods")
        XCTAssertEqual(capturedBody?["name"] as? String, "Banana, raw")
        XCTAssertEqual(capturedBody?["default_unit"] as? String, "g")
        XCTAssertNil(capturedBody?["brand"] as? String)
        XCTAssertNil(capturedBody?["barcode"] as? String)

        let nutrients = capturedBody?["nutrients"] as? [[String: Any]]
        XCTAssertEqual(nutrients?.count, 2)
        XCTAssertEqual(nutrients?.first?["nutrient_key"] as? String, "calories_kcal")
        XCTAssertEqual(nutrients?.first?["value_per_100"] as? Double, 89)

        XCTAssertEqual(result.id, foodId)
        XCTAssertEqual(result.name, "Banana, raw")
        XCTAssertEqual(result.caloriesPer100g, 89)
    }

    func testCreateFoodSendsBarcodeAndVariantsWhenProvided() async throws {
        var capturedBody: [String: Any]?

        StubURLProtocol.requestHandler = { request in
            if let bodyData = request.bodyData,
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                capturedBody = json
            }
            let json = """
            {
                "id": "\(UUID().uuidString)",
                "name": "Yogurt",
                "brand": "Fage",
                "display_name": null,
                "source": "custom",
                "default_unit": "g",
                "nutrients": [{"nutrient_key": "calories_kcal", "value_per_100": "97.0000000000"}],
                "variants": []
            }
            """
            let data = Data(json.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        _ = try await APIClient.shared.createFood(
            name: "Yogurt",
            brand: "Fage",
            barcode: "5449000214911",
            defaultUnit: "g",
            nutrients: [("calories_kcal", 97)],
            variants: [("1 cup", 245, "g")]
        )

        XCTAssertEqual(capturedBody?["barcode"] as? String, "5449000214911")
        let variants = capturedBody?["variants"] as? [[String: Any]]
        XCTAssertEqual(variants?.count, 1)
        XCTAssertEqual(variants?.first?["name"] as? String, "1 cup")
        XCTAssertEqual(variants?.first?["amount"] as? Double, 245)
        XCTAssertEqual(variants?.first?["unit"] as? String, "g")
    }

    /// Regression test for the real server response shape: `POST /api/foods`
    /// returns `FoodOut`, whose `variants` are `VariantOut` — no `id` field,
    /// and `amount` serialized as a quoted decimal string, same as
    /// `nutrients`. Confirmed against the live dev server: creating a food
    /// with a variant decoded to `PorquiloAPIError.decodingError` before
    /// `FoodVariant` grew a custom decoder, even though the food was already
    /// committed server-side.
    func testCreateFoodDecodesResponseVariantWithoutIdAndStringAmount() async throws {
        StubURLProtocol.requestHandler = { request in
            let json = """
            {
                "id": "\(UUID().uuidString)",
                "name": "Rice",
                "brand": "Jasmine",
                "display_name": null,
                "source": "custom",
                "default_unit": "g",
                "nutrients": [{"nutrient_key": "calories_kcal", "value_per_100": "100.0000000000"}],
                "variants": [{"name": "1 cup", "amount": "400.0000000000", "unit": "g"}]
            }
            """
            let data = Data(json.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result = try await APIClient.shared.createFood(
            name: "Rice",
            brand: "Jasmine",
            barcode: nil,
            defaultUnit: "g",
            nutrients: [("calories_kcal", 100)],
            variants: [("1 cup", 400, "g")]
        )

        XCTAssertEqual(result.variants.count, 1)
        XCTAssertEqual(result.variants.first?.name, "1 cup")
        XCTAssertEqual(result.variants.first?.amount, 400)
        XCTAssertEqual(result.variants.first?.unit, "g")
    }

    func testServerErrorDecodesPlainDetailEnvelope() {
        let json = """
        {"detail": "Duplicate barcode or (source, source_id) combination"}
        """
        let data = Data(json.utf8)

        let error = APIClient.serverError(from: data)

        XCTAssertEqual(
            error,
            .serverError(code: "request_failed", message: "Duplicate barcode or (source, source_id) combination")
        )
    }

    func testCreateFoodThrowsDecodedErrorOnDuplicateBarcode() async {
        StubURLProtocol.requestHandler = { request in
            let json = """
            {"detail": "Duplicate barcode or (source, source_id) combination"}
            """
            let data = Data(json.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        do {
            _ = try await APIClient.shared.createFood(
                name: "Yogurt",
                brand: nil,
                barcode: "5449000214911",
                defaultUnit: "g",
                nutrients: [("calories_kcal", 97)],
                variants: []
            )
            XCTFail("Expected createFood to throw")
        } catch PorquiloAPIError.serverError(let code, let message) {
            XCTAssertEqual(code, "request_failed")
            XCTAssertEqual(message, "Duplicate barcode or (source, source_id) combination")
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
