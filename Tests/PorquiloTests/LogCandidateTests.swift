import XCTest
@testable import Porquilo

final class LogCandidateTests: XCTestCase {
    func testInitFromResultMapsFields() {
        let result = FoodSearchResult(
            id: UUID(),
            name: "Overnight oats",
            sourceName: "Pantry",
            subtitle: "Recently logged",
            calorieDisplay: "420 kcal",
            isTopMatch: false
        )

        let candidate = LogCandidate(result: result)

        XCTAssertEqual(candidate.foodId, result.id)
        XCTAssertEqual(candidate.foodName, result.name)
        XCTAssertEqual(candidate.sourceName, result.sourceName)
        XCTAssertEqual(candidate.result, result)
    }
}
