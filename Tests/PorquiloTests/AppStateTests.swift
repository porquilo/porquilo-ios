import XCTest
@testable import Porquilo

final class AppStateTests: XCTestCase {
    override func tearDown() {
        _ = KeychainService.delete()
        super.tearDown()
    }

    func testIsAuthenticatedTrueWhenTokenPresent() {
        _ = KeychainService.save(token: "test-token")
        let appState = AppState()
        XCTAssertTrue(appState.isAuthenticated)
    }

    func testIsAuthenticatedFalseWhenNoToken() {
        _ = KeychainService.delete()
        let appState = AppState()
        XCTAssertFalse(appState.isAuthenticated)
    }
}
