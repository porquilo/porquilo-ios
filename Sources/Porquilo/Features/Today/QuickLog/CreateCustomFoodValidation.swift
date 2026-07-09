import Foundation

/// Mirrors `CreateFoodSheet.tsx`'s `handleSubmit` validation order exactly: name
/// required, calories required and > 0, variant rows validated only when their
/// label is non-empty.
enum CreateCustomFoodValidation {
    struct VariantInput {
        var id: Int
        var label: String
        var weightText: String
    }

    struct VariantResult {
        var id: Int
        var error: String?
    }

    struct Result {
        var nameError: String?
        var kcalError: String?
        var variantResults: [VariantResult]

        var isValid: Bool {
            nameError == nil && kcalError == nil && variantResults.allSatisfy { $0.error == nil }
        }
    }

    static func validate(name: String, kcalText: String, variants: [VariantInput]) -> Result {
        let nameError = name.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Name is required" : nil

        let kcal = Double(kcalText)
        let kcalError = (kcalText.isEmpty || kcal == nil || kcal! <= 0)
            ? "Calories required" : nil

        let variantResults = variants.map { variant -> VariantResult in
            guard !variant.label.trimmingCharacters(in: .whitespaces).isEmpty else {
                return VariantResult(id: variant.id, error: nil)
            }
            let weight = Double(variant.weightText)
            return VariantResult(id: variant.id, error: (weight == nil || weight! <= 0) ? "Weight must be > 0" : nil)
        }

        return Result(nameError: nameError, kcalError: kcalError, variantResults: variantResults)
    }
}
