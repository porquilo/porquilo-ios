import XCTest
@testable import Porquilo

final class CreateCustomFoodValidationTests: XCTestCase {
    func testEmptyNameFails() {
        let result = CreateCustomFoodValidation.validate(name: "", kcalText: "100", variants: [])
        XCTAssertEqual(result.nameError, "Name is required")
    }

    func testZeroCaloriesFails() {
        let result = CreateCustomFoodValidation.validate(name: "Test", kcalText: "0", variants: [])
        XCTAssertEqual(result.kcalError, "Calories required")
    }

    func testMissingCaloriesFails() {
        let result = CreateCustomFoodValidation.validate(name: "Test", kcalText: "", variants: [])
        XCTAssertEqual(result.kcalError, "Calories required")
    }

    func testValidNameAndCaloriesPasses() {
        let result = CreateCustomFoodValidation.validate(name: "Test", kcalText: "100", variants: [])
        XCTAssertTrue(result.isValid)
    }

    func testVariantWithLabelButNoWeightFails() {
        let result = CreateCustomFoodValidation.validate(
            name: "Test",
            kcalText: "100",
            variants: [CreateCustomFoodValidation.VariantInput(id: 1, label: "1 slice", weightText: "")]
        )
        XCTAssertEqual(result.variantResults.first?.error, "Weight must be > 0")
        XCTAssertFalse(result.isValid)
    }

    func testVariantWithZeroWeightFails() {
        let result = CreateCustomFoodValidation.validate(
            name: "Test",
            kcalText: "100",
            variants: [CreateCustomFoodValidation.VariantInput(id: 1, label: "1 slice", weightText: "0")]
        )
        XCTAssertEqual(result.variantResults.first?.error, "Weight must be > 0")
    }

    func testEmptyVariantRowIsIgnored() {
        let result = CreateCustomFoodValidation.validate(
            name: "Test",
            kcalText: "100",
            variants: [CreateCustomFoodValidation.VariantInput(id: 1, label: "", weightText: "")]
        )
        XCTAssertNil(result.variantResults.first?.error)
        XCTAssertTrue(result.isValid)
    }

    func testValidVariantPasses() {
        let result = CreateCustomFoodValidation.validate(
            name: "Test",
            kcalText: "100",
            variants: [CreateCustomFoodValidation.VariantInput(id: 1, label: "1 slice", weightText: "30")]
        )
        XCTAssertNil(result.variantResults.first?.error)
        XCTAssertTrue(result.isValid)
    }
}

final class CreateCustomFoodOriginTests: XCTestCase {
    func testBarcodeOriginHasBlankInitialNameAndBarcodeLogCandidateOrigin() {
        let origin = CreateCustomFoodOrigin.barcode("012345678905")
        XCTAssertEqual(origin.initialName, "")
        XCTAssertEqual(origin.logCandidateOrigin, .barcode)
    }

    func testSearchOriginPrefillsNameAndSearchLogCandidateOrigin() {
        let origin = CreateCustomFoodOrigin.search(query: "Banana")
        XCTAssertEqual(origin.initialName, "Banana")
        XCTAssertEqual(origin.logCandidateOrigin, .search)
    }

    func testBarcodeOriginCandidateHasQuickBarcodeWeightSource() {
        let result = FoodSearchResult(
            id: UUID(),
            name: "Custom food",
            sourceName: "Pantry",
            subtitle: "Pantry",
            nutrientsPer100g: ["calories_kcal": 100],
            isTopMatch: false
        )
        let origin = CreateCustomFoodOrigin.barcode("012345678905")
        let candidate = LogCandidate(result: result, origin: origin.logCandidateOrigin)
        XCTAssertEqual(candidate.origin, .barcode)
        XCTAssertEqual(candidate.weightSource, "quick_barcode")
    }

    func testSearchOriginCandidateHasQuickSearchWeightSource() {
        let result = FoodSearchResult(
            id: UUID(),
            name: "Custom food",
            sourceName: "Pantry",
            subtitle: "Pantry",
            nutrientsPer100g: ["calories_kcal": 100],
            isTopMatch: false
        )
        let origin = CreateCustomFoodOrigin.search(query: "Custom food")
        let candidate = LogCandidate(result: result, origin: origin.logCandidateOrigin)
        XCTAssertEqual(candidate.origin, .search)
        XCTAssertEqual(candidate.weightSource, "quick_search")
    }
}

final class CreateCustomFoodSubmissionTests: XCTestCase {
    private func makeInput(
        name: String = "Banana, raw",
        brand: String = "",
        barcodeText: String = "",
        kcalText: String = "89",
        proteinText: String = "",
        carbsText: String = "",
        fatText: String = "",
        fiberText: String = "",
        sugarText: String = "",
        sodiumText: String = "",
        satFatText: String = "",
        variants: [CreateCustomFoodValidation.VariantInput] = []
    ) -> CreateCustomFoodSubmission.Input {
        CreateCustomFoodSubmission.Input(
            name: name,
            brand: brand,
            barcodeText: barcodeText,
            kcalText: kcalText,
            proteinText: proteinText,
            carbsText: carbsText,
            fatText: fatText,
            fiberText: fiberText,
            sugarText: sugarText,
            sodiumText: sodiumText,
            satFatText: satFatText,
            variants: variants
        )
    }

    func testCaloriesAlwaysIncludedAndOptionalNutrientsOmittedWhenBlank() {
        let output = CreateCustomFoodSubmission.build(
            from: makeInput(kcalText: "89"),
            origin: .search(query: "Banana"),
            unit: "g"
        )
        XCTAssertEqual(output.nutrients, [NutrientEntry(key: "calories_kcal", value: 89)])
    }

    func testOnlyNonEmptyOptionalNutrientFieldsAreIncluded() {
        let output = CreateCustomFoodSubmission.build(
            from: makeInput(kcalText: "89", proteinText: "1.1", sodiumText: "1"),
            origin: .search(query: "Banana"),
            unit: "g"
        )
        XCTAssertEqual(output.nutrients, [
            NutrientEntry(key: "calories_kcal", value: 89),
            NutrientEntry(key: "protein_g", value: 1.1),
            NutrientEntry(key: "sodium_mg", value: 1),
        ])
    }

    func testVariantsOnlyIncludeRowsWithNonEmptyLabelAndPositiveWeight() {
        let output = CreateCustomFoodSubmission.build(
            from: makeInput(variants: [
                CreateCustomFoodValidation.VariantInput(id: 1, label: "1 cup", weightText: "240"),
                CreateCustomFoodValidation.VariantInput(id: 2, label: "", weightText: ""),
                CreateCustomFoodValidation.VariantInput(id: 3, label: "Bad row", weightText: "0"),
            ]),
            origin: .search(query: "Banana"),
            unit: "g"
        )
        XCTAssertEqual(output.variants, [VariantEntry(name: "1 cup", amount: 240, unit: "g")])
    }

    func testBarcodeOriginSubmitsScannedBarcodeRegardlessOfBarcodeText() {
        let output = CreateCustomFoodSubmission.build(
            from: makeInput(barcodeText: "ignored"),
            origin: .barcode("012345678905"),
            unit: "g"
        )
        XCTAssertEqual(output.barcode, "012345678905")
    }

    func testSearchOriginSendsNilBarcodeWhenFieldLeftEmpty() {
        let output = CreateCustomFoodSubmission.build(
            from: makeInput(barcodeText: "   "),
            origin: .search(query: "Banana"),
            unit: "g"
        )
        XCTAssertNil(output.barcode)
    }

    func testSearchOriginSendsTrimmedBarcodeWhenFieldFilledIn() {
        let output = CreateCustomFoodSubmission.build(
            from: makeInput(barcodeText: " 5449000214911 "),
            origin: .search(query: "Banana"),
            unit: "g"
        )
        XCTAssertEqual(output.barcode, "5449000214911")
    }

    func testBlankBrandBecomesNil() {
        let output = CreateCustomFoodSubmission.build(
            from: makeInput(brand: "   "),
            origin: .search(query: "Banana"),
            unit: "g"
        )
        XCTAssertNil(output.brand)
    }
}
