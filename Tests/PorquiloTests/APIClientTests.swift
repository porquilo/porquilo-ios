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
}
