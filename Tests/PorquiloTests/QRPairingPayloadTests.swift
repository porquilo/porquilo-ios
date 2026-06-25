import XCTest
@testable import Porquilo

final class QRPairingPayloadTests: XCTestCase {
    func testValidHTTPSPayloadParses() {
        let raw = #"{"server":"https://test.local","code":"abc"}"#
        let result = QRPairingPayloadParser.parse(raw)

        XCTAssertEqual(result?.serverURL.absoluteString, "https://test.local")
        XCTAssertEqual(result?.code, "abc")
    }

    func testValidHTTPPayloadParses() {
        let raw = #"{"server":"http://test.local","code":"abc"}"#
        let result = QRPairingPayloadParser.parse(raw)

        XCTAssertNotNil(result)
    }

    func testMissingSchemeFailsValidation() {
        let raw = #"{"server":"test.local","code":"abc"}"#
        XCTAssertNil(QRPairingPayloadParser.parse(raw))
    }

    func testMalformedJSONFailsToDecode() {
        let raw = "not json"
        XCTAssertNil(QRPairingPayloadParser.parse(raw))
    }
}
