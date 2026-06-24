import XCTest
@testable import Porquilo

final class KeychainServiceTests: XCTestCase {
    override func tearDown() {
        _ = KeychainService.delete()
        super.tearDown()
    }

    func testSaveAndLoadRoundTrip() {
        XCTAssertTrue(KeychainService.save(token: "test-token"))
        XCTAssertEqual(KeychainService.load(), "test-token")
    }

    func testDeleteRemovesToken() {
        _ = KeychainService.save(token: "test-token")
        XCTAssertTrue(KeychainService.delete())
        XCTAssertNil(KeychainService.load())
    }
}
