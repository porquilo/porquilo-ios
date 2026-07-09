import SwiftUI

/// Where the "create a custom food" flow was entered from. Determines the
/// initial Name value, whether Barcode is read-only or editable, where the
/// back button returns to, and which `LogCandidate.Origin` (and therefore
/// `weight_source`) the created food logs under.
enum CreateCustomFoodOrigin: Equatable {
    case barcode(String)
    case search(query: String)
}

extension CreateCustomFoodOrigin {
    var initialName: String {
        switch self {
        case .barcode: return ""
        case .search(let query): return query
        }
    }

    var logCandidateOrigin: LogCandidate.Origin {
        switch self {
        case .barcode: return .barcode
        case .search: return .search
        }
    }
}

struct NutrientEntry: Equatable {
    let key: String
    let value: Double
}

struct VariantEntry: Equatable {
    let name: String
    let amount: Double
    let unit: String
}

/// Builds the `POST /api/foods` payload from the form's raw text state. Pulled
/// out of the view's `submit()` so the "only non-empty optional fields, only
/// valid variant rows" logic is unit-testable without driving SwiftUI.
enum CreateCustomFoodSubmission {
    struct Input {
        var name: String
        var brand: String
        var barcodeText: String
        var kcalText: String
        var proteinText: String
        var carbsText: String
        var fatText: String
        var fiberText: String
        var sugarText: String
        var sodiumText: String
        var satFatText: String
        var variants: [CreateCustomFoodValidation.VariantInput]
    }

    struct Output: Equatable {
        var name: String
        var brand: String?
        var barcode: String?
        var nutrients: [NutrientEntry]
        var variants: [VariantEntry]
    }

    static func build(from input: Input, origin: CreateCustomFoodOrigin, unit: String) -> Output {
        let barcode: String?
        switch origin {
        case .barcode(let code):
            barcode = code
        case .search:
            let trimmed = input.barcodeText.trimmingCharacters(in: .whitespaces)
            barcode = trimmed.isEmpty ? nil : trimmed
        }

        let trimmedBrand = input.brand.trimmingCharacters(in: .whitespaces)

        let nutrients: [NutrientEntry] = [NutrientEntry(key: "calories_kcal", value: Double(input.kcalText) ?? 0)]
            + [
                optionalNutrient("protein_g", input.proteinText),
                optionalNutrient("carbs_g", input.carbsText),
                optionalNutrient("fat_g", input.fatText),
                optionalNutrient("fiber_g", input.fiberText),
                optionalNutrient("sugar_g", input.sugarText),
                optionalNutrient("sodium_mg", input.sodiumText),
                optionalNutrient("saturated_fat_g", input.satFatText),
            ].compactMap { $0 }

        let variants: [VariantEntry] = input.variants.compactMap { row in
            let trimmedLabel = row.label.trimmingCharacters(in: .whitespaces)
            guard !trimmedLabel.isEmpty, let weight = Double(row.weightText), weight > 0 else { return nil }
            return VariantEntry(name: trimmedLabel, amount: weight, unit: unit)
        }

        return Output(
            name: input.name.trimmingCharacters(in: .whitespaces),
            brand: trimmedBrand.isEmpty ? nil : trimmedBrand,
            barcode: barcode,
            nutrients: nutrients,
            variants: variants
        )
    }

    private static func optionalNutrient(_ key: String, _ text: String) -> NutrientEntry? {
        guard !text.isEmpty else { return nil }
        return NutrientEntry(key: key, value: Double(text) ?? 0)
    }
}

struct CreateCustomFoodView: View {
    let origin: CreateCustomFoodOrigin
    @Binding var step: QuickLogStep
    let onDismiss: () -> Void
    @Environment(AppState.self) private var appState

    private struct VariantRow: Identifiable {
        let id: Int
        var label: String
        var weightText: String
        var error: String?
    }

    @State private var name: String
    @State private var brand: String = ""
    @State private var barcodeText: String
    @State private var unit: String = "g"

    @State private var kcalText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatText: String = ""

    @State private var showMoreNutrients: Bool = false
    @State private var fiberText: String = ""
    @State private var sugarText: String = ""
    @State private var sodiumText: String = ""
    @State private var satFatText: String = ""

    @State private var variants: [VariantRow] = []
    @State private var nextVariantId: Int = 0

    @State private var nameError: String?
    @State private var kcalError: String?
    @State private var apiError: String?
    @State private var isSubmitting: Bool = false

    private let gridColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    init(origin: CreateCustomFoodOrigin, step: Binding<QuickLogStep>, onDismiss: @escaping () -> Void) {
        self.origin = origin
        self._step = step
        self.onDismiss = onDismiss
        self._name = State(initialValue: origin.initialName)
        self._barcodeText = State(initialValue: "")
    }

    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        identitySection
                        unitToggleSection
                        requiredNutrientsSection
                        showMoreNutrientsSection
                        variantsSection

                        if let apiError {
                            apiErrorBanner(apiError)
                        }

                        submitButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("Add custom food")
                .font(.custom("Newsreader", size: 18))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack {
                Button(action: goBack) {
                    Text(backLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DesignTokens.accent)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
        }
    }

    private var backLabel: String {
        switch origin {
        case .barcode: return "← Not found"
        case .search: return "← Quick log"
        }
    }

    private func goBack() {
        switch origin {
        case .barcode(let code): step = .barcodeNotFound(barcode: code)
        case .search: step = .search
        }
    }

    // MARK: - Identity section

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch origin {
            case .barcode(let code):
                fieldLabel("Barcode")
                barcodeChip(code)
            case .search:
                fieldLabel("Barcode")
                fieldContainer(isError: false) {
                    TextField(
                        "",
                        text: $barcodeText,
                        prompt: Text("e.g. 5449000214911 (optional)").foregroundStyle(DesignTokens.textMuted)
                    )
                    .font(.system(size: 14))
                    .keyboardType(.numbersAndPunctuation)
                }
            }

            fieldLabel("Name *")
            fieldContainer(isError: nameError != nil) {
                TextField("", text: $name, prompt: Text("e.g. Banana, raw").foregroundStyle(DesignTokens.textMuted))
                    .font(.system(size: 14))
                    .onChange(of: name) { _, _ in nameError = nil }
            }
            if let nameError {
                errorRow(nameError)
            }

            fieldLabel("Brand")
            fieldContainer(isError: false) {
                TextField("", text: $brand, prompt: Text("e.g. Fage (optional)").foregroundStyle(DesignTokens.textMuted))
                    .font(.system(size: 14))
            }
        }
    }

    private func barcodeChip(_ code: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "barcode")
                .font(.system(size: 12))
            Text(code)
                .font(.custom("Geist Mono", size: 12))
                .tracking(0.06 * 12)
        }
        .foregroundStyle(DesignTokens.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(DesignTokens.backgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Default unit toggle

    private var unitToggleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Default unit")
            HStack(spacing: 6) {
                unitButton("g")
                unitButton("ml")
            }
        }
    }

    private func unitButton(_ value: String) -> some View {
        let isSelected = unit == value
        return Button(action: { unit = value }) {
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? DesignTokens.accent : DesignTokens.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? DesignTokens.accentSoftBackground : DesignTokens.backgroundSunken)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? DesignTokens.accent : DesignTokens.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Required nutrients

    private var requiredNutrientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Nutrients per 100 \(unit)")
            LazyVGrid(columns: gridColumns, spacing: 10) {
                nutrientField(label: "Calories (kcal) *", text: $kcalText, isError: kcalError != nil, errorMessage: kcalError)
                    .onChange(of: kcalText) { _, _ in kcalError = nil }
                nutrientField(label: "Protein (g)", text: $proteinText)
                nutrientField(label: "Carbs (g)", text: $carbsText)
                nutrientField(label: "Fat (g)", text: $fatText)
            }
        }
    }

    private func nutrientField(
        label: String,
        text: Binding<String>,
        isError: Bool = false,
        errorMessage: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel(label)
            fieldContainer(isError: isError) {
                TextField("", text: text, prompt: Text("0").foregroundStyle(DesignTokens.textMuted))
                    .font(.system(size: 14))
                    .keyboardType(.decimalPad)
            }
            if let errorMessage {
                errorRow(errorMessage)
            }
        }
    }

    // MARK: - Optional nutrients

    private var showMoreNutrientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: { showMoreNutrients.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: showMoreNutrients ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                    Text(showMoreNutrients ? "Show less" : "Show more nutrients")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(DesignTokens.textTertiary)
            }

            if showMoreNutrients {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    nutrientField(label: "Fiber (g)", text: $fiberText)
                    nutrientField(label: "Sugar (g)", text: $sugarText)
                    nutrientField(label: "Sodium (mg)", text: $sodiumText)
                    nutrientField(label: "Sat. fat (g)", text: $satFatText)
                }
            }
        }
    }

    // MARK: - Serving variants

    private var variantsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Serving variants")

            ForEach(variants) { row in
                variantRow(row)
            }

            Button(action: addVariant) {
                Text("+ Add variant")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(DesignTokens.border)
                    )
            }
        }
    }

    private func variantRow(_ row: VariantRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                fieldContainer(isError: false) {
                    TextField(
                        "",
                        text: labelBinding(for: row.id),
                        prompt: Text("e.g. 1 cup").foregroundStyle(DesignTokens.textMuted)
                    )
                    .font(.system(size: 14))
                }

                fieldContainer(isError: row.error != nil) {
                    TextField(
                        "",
                        text: weightBinding(for: row.id),
                        prompt: Text(unit).foregroundStyle(DesignTokens.textMuted)
                    )
                    .font(.system(size: 14))
                    .keyboardType(.decimalPad)
                }
                .frame(width: 80)

                Button(action: { removeVariant(row.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }

            if let error = row.error {
                errorRow(error)
            }
        }
    }

    private func labelBinding(for id: Int) -> Binding<String> {
        Binding(
            get: { variants.first(where: { $0.id == id })?.label ?? "" },
            set: { newValue in
                guard let index = variants.firstIndex(where: { $0.id == id }) else { return }
                variants[index].label = newValue
                variants[index].error = nil
            }
        )
    }

    private func weightBinding(for id: Int) -> Binding<String> {
        Binding(
            get: { variants.first(where: { $0.id == id })?.weightText ?? "" },
            set: { newValue in
                guard let index = variants.firstIndex(where: { $0.id == id }) else { return }
                variants[index].weightText = newValue
                variants[index].error = nil
            }
        )
    }

    private func addVariant() {
        variants.append(VariantRow(id: nextVariantId, label: "", weightText: "", error: nil))
        nextVariantId += 1
    }

    private func removeVariant(_ id: Int) {
        variants.removeAll { $0.id == id }
    }

    // MARK: - API error banner

    private func apiErrorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(DesignTokens.dangerForeground)
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.dangerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Submit button

    private var submitButton: some View {
        Button(action: submit) {
            Group {
                if isSubmitting {
                    ProgressView().tint(DesignTokens.textOnAccent)
                } else {
                    Text("Add to library")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(DesignTokens.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(DesignTokens.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSubmitting)
    }

    // MARK: - Shared field styling

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.06 * 11)
            .foregroundStyle(DesignTokens.textTertiary)
            .textCase(.uppercase)
    }

    private func fieldContainer<Content: View>(isError: Bool, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignTokens.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isError ? DesignTokens.dangerForeground : DesignTokens.border,
                                lineWidth: isError ? 1.5 : 1
                            )
                    )
            )
    }

    private func errorRow(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
                .font(.system(size: 12))
        }
        .foregroundStyle(DesignTokens.dangerForeground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(DesignTokens.dangerBackground))
    }

    // MARK: - Submit

    private func submit() {
        let variantInputs = variants.map {
            CreateCustomFoodValidation.VariantInput(id: $0.id, label: $0.label, weightText: $0.weightText)
        }
        let result = CreateCustomFoodValidation.validate(name: name, kcalText: kcalText, variants: variantInputs)

        nameError = result.nameError
        kcalError = result.kcalError
        for variantResult in result.variantResults {
            guard let index = variants.firstIndex(where: { $0.id == variantResult.id }) else { continue }
            variants[index].error = variantResult.error
        }

        guard result.isValid else { return }

        let submission = CreateCustomFoodSubmission.build(
            from: CreateCustomFoodSubmission.Input(
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
                variants: variantInputs
            ),
            origin: origin,
            unit: unit
        )

        isSubmitting = true
        apiError = nil

        Task {
            do {
                let created = try await APIClient.shared.createFood(
                    name: submission.name,
                    brand: submission.brand,
                    barcode: submission.barcode,
                    defaultUnit: unit,
                    nutrients: submission.nutrients.map { ($0.key, $0.value) },
                    variants: submission.variants.map { ($0.name, $0.amount, $0.unit) }
                )
                isSubmitting = false
                let newCandidate = LogCandidate(result: created, origin: origin.logCandidateOrigin)
                step = .quantity(newCandidate)
            } catch PorquiloAPIError.unauthorized {
                isSubmitting = false
                appState.signOut()
            } catch {
                isSubmitting = false
                apiError = error.localizedDescription
            }
        }
    }
}
