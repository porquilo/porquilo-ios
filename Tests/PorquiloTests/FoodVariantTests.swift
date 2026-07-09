import XCTest
@testable import Porquilo

final class FoodVariantTests: XCTestCase {
    func testDecodesWithIdAndStringAmount_searchShape() throws {
        let json = """
        {"id": "4ee5b72d-6093-41f7-ae06-184cd3fc2a6f", "name": "1 cup", "amount": "400.0000000000", "unit": "g"}
        """
        let variant = try JSONDecoder().decode(FoodVariant.self, from: Data(json.utf8))

        XCTAssertEqual(variant.id, UUID(uuidString: "4ee5b72d-6093-41f7-ae06-184cd3fc2a6f"))
        XCTAssertEqual(variant.name, "1 cup")
        XCTAssertEqual(variant.amount, 400.0)
        XCTAssertEqual(variant.unit, "g")
    }

    /// `VariantOut` — the shape used by `FoodOut` (barcode lookup,
    /// `POST /api/foods`, patch/get-by-id) — has no `id` key at all.
    func testDecodesWithoutId_foodOutShape() throws {
        let json = """
        {"name": "1 cup", "amount": "400.0000000000", "unit": "g"}
        """
        let variant = try JSONDecoder().decode(FoodVariant.self, from: Data(json.utf8))

        XCTAssertEqual(variant.name, "1 cup")
        XCTAssertEqual(variant.amount, 400.0)
        XCTAssertEqual(variant.unit, "g")
    }

    func testDecodesRawNumberAmount() throws {
        let json = """
        {"name": "1 cup", "amount": 400.0, "unit": "g"}
        """
        let variant = try JSONDecoder().decode(FoodVariant.self, from: Data(json.utf8))
        XCTAssertEqual(variant.amount, 400.0)
    }

    func testDecodesNilAmountAndName() throws {
        let json = """
        {"name": null, "amount": null, "unit": "g"}
        """
        let variant = try JSONDecoder().decode(FoodVariant.self, from: Data(json.utf8))
        XCTAssertNil(variant.name)
        XCTAssertNil(variant.amount)
    }

    func testTwoVariantsWithoutIdGetDistinctSynthesizedIds() throws {
        let json = """
        {"name": "1 cup", "amount": "240.0", "unit": "g"}
        """
        let first = try JSONDecoder().decode(FoodVariant.self, from: Data(json.utf8))
        let second = try JSONDecoder().decode(FoodVariant.self, from: Data(json.utf8))
        XCTAssertNotEqual(first.id, second.id)
    }
}
