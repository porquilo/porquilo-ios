import XCTest
@testable import Porquilo

final class ManualEntryValidationTests: XCTestCase {
    func testEmptyURLFails() {
        let result = ManualEntryValidation.validate(url: "", username: "u", password: "p")
        XCTAssertEqual(result.urlError, "Enter your server address.")
        XCTAssertNil(result.credError)
    }

    func testMissingSchemeFails() {
        let result = ManualEntryValidation.validate(url: "nutrition.home.local", username: "u", password: "p")
        XCTAssertEqual(result.urlError, "Address must start with https:// or http://")
    }

    func testEmptyUsernameFailsAfterURLPasses() {
        let result = ManualEntryValidation.validate(url: "https://nutrition.home.local", username: "", password: "p")
        XCTAssertNil(result.urlError)
        XCTAssertEqual(result.credError, "Username is required.")
    }

    func testEmptyPasswordFailsAfterUsernamePasses() {
        let result = ManualEntryValidation.validate(url: "https://nutrition.home.local", username: "u", password: "")
        XCTAssertEqual(result.credError, "Password is required.")
    }

    func testAllValidPassesWithNoErrors() {
        let result = ManualEntryValidation.validate(url: "https://nutrition.home.local", username: "u", password: "p")
        XCTAssertNil(result.urlError)
        XCTAssertNil(result.credError)
    }
}
