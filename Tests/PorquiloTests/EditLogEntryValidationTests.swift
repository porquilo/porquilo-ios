import XCTest
@testable import Porquilo

final class EditLogEntryValidationTests: XCTestCase {
    func testZeroQuantityFails() {
        XCTAssertEqual(EditLogEntryValidation.validate(quantityText: "0"), "Quantity must be greater than 0")
    }

    func testEmptyQuantityFails() {
        XCTAssertEqual(EditLogEntryValidation.validate(quantityText: ""), "Quantity must be greater than 0")
    }

    func testValidQuantityPasses() {
        XCTAssertNil(EditLogEntryValidation.validate(quantityText: "150"))
    }

    func testNegativeQuantityFails() {
        XCTAssertEqual(EditLogEntryValidation.validate(quantityText: "-10"), "Quantity must be greater than 0")
    }

    func testScaleSourceWithChangedQuantityDemotesToQuickSearch() {
        let result = EditLogEntryValidation.weightSourceToSend(originalWeightSource: "scale", quantityChanged: true)
        XCTAssertEqual(result, "quick_search")
    }

    func testScaleSourceWithUnchangedQuantityOmitsWeightSource() {
        let result = EditLogEntryValidation.weightSourceToSend(originalWeightSource: "scale", quantityChanged: false)
        XCTAssertNil(result)
    }

    func testNonScaleSourceWithChangedQuantityOmitsWeightSource() {
        let result = EditLogEntryValidation.weightSourceToSend(originalWeightSource: "quick_search", quantityChanged: true)
        XCTAssertNil(result)
    }

    func testNonScaleSourceWithUnchangedQuantityOmitsWeightSource() {
        let result = EditLogEntryValidation.weightSourceToSend(originalWeightSource: "quick_search", quantityChanged: false)
        XCTAssertNil(result)
    }
}
