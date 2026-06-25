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

    func testCompleteAuthSetsIsAuthenticatedAndStoresServerURL() {
        let appState = AppState(tokenLoader: { nil })
        appState.completeAuth(token: "test-token", serverURL: "https://test.local")

        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppConstants.serverURLKey), "https://test.local")

        appState.signOut()
    }

    func testSignOutClearsAuthenticatedStateAndCurrentUser() {
        let appState = AppState(tokenLoader: { nil })
        appState.completeAuth(token: "test-token", serverURL: "https://test.local")

        appState.signOut()

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.currentUser)
        XCTAssertNil(UserDefaults.standard.string(forKey: AppConstants.serverURLKey))
    }

    func testIsVersionSufficientEqualVersions() {
        XCTAssertTrue(AppState.isVersionSufficient("1.3.0", minimum: "1.3.0"))
    }

    func testIsVersionSufficientGreaterMinor() {
        XCTAssertTrue(AppState.isVersionSufficient("1.4.0", minimum: "1.3.0"))
    }

    func testIsVersionSufficientLesserPatch() {
        XCTAssertFalse(AppState.isVersionSufficient("1.2.9", minimum: "1.3.0"))
    }

    func testIsVersionSufficientUnparseableFailsOpen() {
        XCTAssertTrue(AppState.isVersionSufficient("unparseable", minimum: "1.0.0"))
    }
}
