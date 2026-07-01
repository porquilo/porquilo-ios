import SwiftUI

enum ServingMode: Equatable, Hashable {
    case per100g
    case variant(FoodVariant)
    case wholeItem
    case servings
    case custom
}

struct QuantityView: View {
    let candidate: LogCandidate
    @Binding var step: QuickLogStep
    let onLogged: () -> Void
    @Environment(AppState.self) private var appState

    /// Mock conversion factors — real per-unit gram weights arrive with the
    /// nutrition API in a later session; these keep the live preview internally
    /// consistent in the meantime.
    private static let cupGrams: Double = 240
    private static let itemGrams: Double = 235

    @State private var servingMode: ServingMode
    @State private var quantity: Double
    @State private var customText: String = ""
    @State private var eatenAt: Date = Date().roundedToNearest15Minutes()
    @State private var meals: [Meal]
    @State private var selectedMeal: Meal?
    @State private var showMealPicker: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var submitError: String? = nil
    @FocusState private var isQuantityFieldFocused: Bool

    private var isBarcode: Bool { candidate.origin == .barcode }

    init(candidate: LogCandidate, meals: [Meal], step: Binding<QuickLogStep>, onLogged: @escaping () -> Void) {
        self.candidate = candidate
        self._step = step
        self.onLogged = onLogged
        self._servingMode = State(initialValue: candidate.origin == .barcode ? .wholeItem : .per100g)
        self._quantity = State(initialValue: candidate.origin == .barcode ? 1.0 : 100.0)
        self._meals = State(initialValue: meals)
        self._selectedMeal = State(initialValue: Meal.inferredDefault(from: meals, at: Date()))
    }

    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if isBarcode {
                            productCard
                        } else {
                            sourceRow
                        }

                        servingSelector
                        quantityDisplay
                        macroPreviewCard
                        mealChip

                        if let submitError {
                            Text(submitError)
                                .font(.system(size: 12))
                                .foregroundStyle(DesignTokens.dangerForeground)
                        }

                        logButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showMealPicker) {
            MealTimePickerSheet(meals: meals, selectedMeal: $selectedMeal, eatenAt: $eatenAt)
        }
        .onChange(of: servingMode) { _, newMode in
            switch newMode {
            case .per100g:
                quantity = 100
            case .variant(let variant):
                if let amount = variant.amount { quantity = amount }
            case .wholeItem, .servings, .custom:
                break
            }
        }
        .task {
            if meals.isEmpty {
                meals = (try? await APIClient.shared.fetchMeals()) ?? []
                if selectedMeal == nil {
                    selectedMeal = Meal.inferredDefault(from: meals, at: eatenAt)
                }
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text(candidate.foodName)
                .font(.custom("Newsreader", size: isBarcode ? 16 : 18))
                .foregroundStyle(DesignTokens.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 116)

            HStack {
                Button(action: { step = .search }) {
                    Text("← Quick log")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignTokens.accent)
                }
                Spacer()
                Spacer().frame(width: 80)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
        }
    }

    // MARK: - Barcode product card

    private var productCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(candidate.foodName)
                        .font(.custom("Newsreader", size: 17))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text(candidate.result.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    Image(systemName: "barcode")
                        .font(.system(size: 10))
                    Text("BARCODE")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.06 * 9)
                }
                .foregroundStyle(DesignTokens.textTertiary)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(DesignTokens.backgroundSunken)
                .clipShape(Capsule())
            }

            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
                .padding(.top, 4)

            Text("1 serving = \(Int(Self.itemGrams)) ml · Open Food Facts")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.textTertiary)
                .padding(.top, 4)
        }
        .padding(14)
        .background(DesignTokens.backgroundElevated)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DesignTokens.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .applyShadow1()
    }

    // MARK: - Text search source row

    private var sourceRow: some View {
        HStack {
            Text("\(candidate.sourceName) · raw values per serving")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textTertiary)
            Spacer()
            Text("Estimated")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DesignTokens.confidenceEstimatedFg)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(DesignTokens.confidenceEstimatedBg)
                .clipShape(Capsule())
        }
    }

    // MARK: - Serving selector

    /// "Per 100 g" and "Custom" bookend the food's named variants (if any).
    /// Unnamed variants (no display label) are skipped.
    private var textSearchServingModes: [ServingMode] {
        let namedVariants = candidate.variants
            .filter { $0.name != nil }
            .map { ServingMode.variant($0) }
        return [.per100g] + namedVariants + [.custom]
    }

    private var barcodeServingModes: [ServingMode] {
        [.wholeItem, .servings, .custom]
    }

    private func servingModeLabel(_ mode: ServingMode) -> String {
        switch mode {
        case .per100g: return "Per 100 g"
        case .variant(let variant): return variant.name ?? ""
        case .wholeItem: return "Whole item"
        case .servings: return "Servings"
        case .custom: return isBarcode ? "Custom g" : "Custom"
        }
    }

    private var servingSelector: some View {
        HStack(spacing: 2) {
            ForEach(isBarcode ? barcodeServingModes : textSearchServingModes, id: \.self) { mode in
                Button(action: { servingMode = mode }) {
                    Text(servingModeLabel(mode))
                        .font(.system(size: 13, weight: servingMode == mode ? .semibold : .medium))
                        .foregroundStyle(servingMode == mode ? DesignTokens.textPrimary : DesignTokens.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(servingMode == mode ? DesignTokens.backgroundElevated : Color.clear)
                        .applyShadow1()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(3)
        .background(DesignTokens.backgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Quantity display

    @ViewBuilder
    private var quantityDisplay: some View {
        switch servingMode {
        case .per100g, .variant, .servings:
            VStack(spacing: 4) {
                Text(formattedQuantity)
                    .font(.custom("Geist Mono", size: 56))
                    .fontWeight(.medium)
                    .tracking(-0.025 * 56)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .monospacedDigit()
                    .focusable()
                Text(unitLabel)
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { isQuantityFieldFocused = true }
            .overlay {
                TextField("", value: $quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($isQuantityFieldFocused)
                    .opacity(0.01)
            }

        case .wholeItem:
            HStack(spacing: 18) {
                stepperButton(systemName: "minus") {
                    quantity = max(0, quantity - 1)
                }
                Text(formattedQuantity)
                    .font(.custom("Geist Mono", size: 52))
                    .fontWeight(.medium)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .monospacedDigit()
                stepperButton(systemName: "plus") {
                    quantity += 1
                }
            }
            .frame(maxWidth: .infinity)
            VStack {
                Text(unitLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .frame(maxWidth: .infinity)

        case .custom:
            TextField("0", text: $customText)
                .font(.custom("Geist Mono", size: 24))
                .keyboardType(.decimalPad)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(DesignTokens.backgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DesignTokens.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: customText) { _, newValue in
                    quantity = Double(newValue) ?? 0
                }
        }
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22))
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 40, height: 40)
                .background(DesignTokens.backgroundSunken)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DesignTokens.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var formattedQuantity: String {
        if quantity == quantity.rounded() {
            return String(Int(quantity))
        }
        return String(format: "%.1f", quantity)
    }

    private var unitLabel: String {
        switch servingMode {
        case .per100g: return "g"
        case .variant(let variant): return variant.unit
        case .servings: return "serving · \(Int(Self.cupGrams)) ml"
        case .wholeItem: return "item · \(Int(Self.itemGrams)) ml"
        case .custom: return "g"
        }
    }

    // MARK: - Macro math

    private var gramsEquivalent: Double {
        switch servingMode {
        case .per100g, .custom: return quantity
        case .variant(let variant): return quantity * (variant.amount ?? 1)
        case .servings: return quantity * Self.cupGrams
        case .wholeItem: return quantity * Self.itemGrams
        }
    }

    private var totalCalories: Double {
        (candidate.result.caloriesPer100g / 100) * gramsEquivalent
    }

    private var proteinGrams: Double { (candidate.result.proteinPer100g / 100) * gramsEquivalent }
    private var carbsGrams: Double { (candidate.result.carbsPer100g / 100) * gramsEquivalent }
    private var fatGrams: Double { (candidate.result.fatPer100g / 100) * gramsEquivalent }

    private var macroPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("~")
                    .font(.custom("Geist Mono", size: 13))
                    .fontWeight(.medium)
                    .foregroundStyle(DesignTokens.confidenceEstimatedFg)
                Text(String(Int(totalCalories.rounded())))
                    .font(.custom("Geist Mono", size: 40))
                    .fontWeight(.medium)
                    .tracking(-0.025 * 40)
                    .foregroundStyle(DesignTokens.confidenceEstimatedFg)
                    .monospacedDigit()
                Text("kcal")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textTertiary)
            }

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Rectangle().fill(DesignTokens.herb500).frame(width: proxy.size.width * 0.30)
                    Rectangle().fill(DesignTokens.honey500).frame(width: proxy.size.width * 0.45)
                    Rectangle().fill(DesignTokens.clay500).frame(width: proxy.size.width * 0.25)
                }
            }
            .frame(height: 6)
            .background(DesignTokens.backgroundSunken)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            HStack {
                macroColumn(label: "PROTEIN", grams: proteinGrams)
                macroColumn(label: "CARBS", grams: carbsGrams)
                macroColumn(label: "FAT", grams: fatGrams)
            }
        }
        .padding(14)
        .background(DesignTokens.backgroundElevated)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DesignTokens.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .applyShadow2()
    }

    private func macroColumn(label: String, grams: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.07 * 10)
                .foregroundStyle(DesignTokens.textTertiary)
            HStack(spacing: 1) {
                Text("~\(String(format: "%.1f", grams))")
                    .font(.custom("Geist Mono", size: 15))
                    .fontWeight(.medium)
                    .foregroundStyle(DesignTokens.confidenceEstimatedFg)
                    .monospacedDigit()
                Text(" g")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Meal chip

    private var mealChip: some View {
        Button(action: { showMealPicker = true }) {
            HStack(spacing: 6) {
                Text("Adding to")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textSecondary)
                Text(selectedMeal?.name ?? "Meal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("·")
                    .foregroundStyle(DesignTokens.textMuted)
                Text(timeLabel)
                    .font(.custom("Geist Mono", size: 14))
                    .fontWeight(.medium)
                    .foregroundStyle(DesignTokens.textPrimary)

                Spacer()

                Text("change")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.accent)
                    .underline()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(DesignTokens.backgroundElevated)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DesignTokens.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .applyShadow1()
        }
        .buttonStyle(.plain)
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: eatenAt)
    }

    // MARK: - Log button

    private var logButton: some View {
        Button(action: submit) {
            Group {
                if isSubmitting {
                    ProgressView().tint(DesignTokens.textOnAccent)
                } else {
                    Text("Log")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(DesignTokens.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(DesignTokens.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: DesignTokens.accent.opacity(0.30), radius: 7, y: 4)
        }
        .disabled(isSubmitting)
    }

    private func submit() {
        guard let selectedMeal else {
            submitError = "No meal selected."
            return
        }

        isSubmitting = true
        submitError = nil

        Task {
            do {
                try await APIClient.shared.createLogEntry(
                    foodId: candidate.foodId,
                    mealId: selectedMeal.id,
                    weightG: gramsEquivalent,
                    eatenAt: eatenAt,
                    weightSource: candidate.weightSource,
                    inputMethod: isBarcode ? "quick_barcode" : "quick_log"
                )
                isSubmitting = false
                onLogged()
            } catch PorquiloAPIError.unauthorized {
                isSubmitting = false
                appState.signOut()
            } catch {
                isSubmitting = false
                submitError = error.localizedDescription
            }
        }
    }
}
