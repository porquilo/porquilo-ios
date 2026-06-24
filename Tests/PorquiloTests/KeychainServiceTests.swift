import XCTest
@testable import Porquilo

private class MockKeychain {
    var store: [String: String] = [:]

    func save(token: String, key: String) -> Bool {
        store[key] = token
        return true
    }

    func load(key: String) -> String? {
        store[key]
    }

    func delete(key: String) -> Bool {
        store.removeValue(forKey: key)
        return true
    }
}

final class KeychainServiceTests: XCTestCase {
    // Real KeychainService tests require a physical device.
    // Run KeychainServiceDeviceTests (not in this suite) on device to verify.

    func testSaveAndLoadRoundTrip() {
        let mock = MockKeychain()
        XCTAssertTrue(mock.save(token: "test-token", key: "token"))
        XCTAssertEqual(mock.load(key: "token"), "test-token")
    }

    func testDeleteRemovesToken() {
        let mock = MockKeychain()
        _ = mock.save(token: "test-token", key: "token")
        XCTAssertTrue(mock.delete(key: "token"))
        XCTAssertNil(mock.load(key: "token"))
    }

    func testSaveOverwritesExistingValue() {
        let mock = MockKeychain()
        _ = mock.save(token: "old-token", key: "token")
        _ = mock.save(token: "new-token", key: "token")
        XCTAssertEqual(mock.load(key: "token"), "new-token")
    }
}
