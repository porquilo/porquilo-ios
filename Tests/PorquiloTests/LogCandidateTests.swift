import XCTest
@testable import Porquilo

final class LogCandidateTests: XCTestCase {
    func testInitFromResultMapsFields() {
        let result = FoodSearchResult(
            id: UUID(),
            name: "Overnight oats",
            sourceName: "Pantry",
            subtitle: "Recently logged",
            nutrientsPer100g: ["calories_kcal": 420],
            isTopMatch: false
        )

        let candidate = LogCandidate(result: result)

        XCTAssertEqual(candidate.foodId, result.id)
        XCTAssertEqual(candidate.foodName, result.name)
        XCTAssertEqual(candidate.sourceName, result.sourceName)
        XCTAssertEqual(candidate.origin, .search)
        XCTAssertEqual(candidate.result, result)
    }

    func testInitFromResultDefaultsAndAcceptsOrigin() {
        let result = FoodSearchResult(
            id: UUID(),
            name: "Cola",
            sourceName: "Barcode",
            subtitle: "Open Food Facts",
            nutrientsPer100g: ["calories_kcal": 42],
            isTopMatch: false
        )

        let candidate = LogCandidate(result: result, origin: .barcode)

        XCTAssertEqual(candidate.origin, .barcode)
    }
}
