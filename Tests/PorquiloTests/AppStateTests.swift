import XCTest
@testable import Porquilo

final class AppStateTests: XCTestCase {
    func testIsAuthenticatedTrueWhenTokenPresent() {
        let appState = AppState(tokenLoader: { "fake-token" })
        XCTAssertTrue(appState.isAuthenticated)
    }

    func testIsAuthenticatedFalseWhenNoToken() {
        let appState = AppState(tokenLoader: { nil })
        XCTAssertFalse(appState.isAuthenticated)
    }
}
