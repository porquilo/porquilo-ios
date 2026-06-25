import SwiftUI

struct QuickLogSearchView: View {
    @Binding var step: QuickLogStep
    @Binding var candidate: LogCandidate?
    @Binding var isOffline: Bool
    let onDismiss: () -> Void

    @State private var query: String = ""
    @State private var results: [FoodSearchResult] = []
    @State private var isLoading: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchTask: Task<Void, Never>?

    private static let recentSamples: [FoodSearchResult] = [
        FoodSearchResult(id: UUID(), name: "Overnight oats", sourceName: "Pantry", subtitle: "Recently logged", calorieDisplay: "420 kcal", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Oat milk 1 cup", sourceName: "Pantry", subtitle: "Recently logged", calorieDisplay: "49 kcal", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Greek yogurt plain", sourceName: "USDA", subtitle: "Recently logged", calorieDisplay: "/100 g", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Brown rice cooked", sourceName: "USDA", subtitle: "Recently logged", calorieDisplay: "/100 g", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Banana raw", sourceName: "USDA", subtitle: "Recently logged", calorieDisplay: "/100 g", isTopMatch: false),
    ]

    private static let frequentSamples: [FoodSearchResult] = [
        FoodSearchResult(id: UUID(), name: "Overnight oats", sourceName: "Pantry", subtitle: "47 times logged", calorieDisplay: "420 kcal", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Oat milk", sourceName: "Pantry", subtitle: "31 times logged", calorieDisplay: "49 kcal", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Eggs scrambled", sourceName: "Pantry", subtitle: "24 times logged", calorieDisplay: "148 kcal", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Greek yogurt", sourceName: "Pantry", subtitle: "18 times logged", calorieDisplay: "100 kcal", isTopMatch: false),
        FoodSearchResult(id: UUID(), name: "Chicken salad wrap", sourceName: "Pantry", subtitle: "11 times logged", calorieDisplay: "410 kcal", isTopMatch: false),
    ]

    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                searchBar

                if isOffline {
                    offlineBanner
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if query.isEmpty {
                            emptyStateContent
                        } else {
                            resultsContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: query) { _, newValue in
            scheduleSearch(for: newValue)
        }
    }

    private var navBar: some View {
        ZStack {
            Text("Quick log")
                .font(.custom("Newsreader", size: 18))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack {
                Spacer().frame(width: 64)
                Spacer()
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DesignTokens.accent)
                        .frame(width: 64, alignment: .trailing)
                }
            }
        }
        .frame(height: 50)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(DesignTokens.textTertiary)
                .frame(width: 16, height: 16)

            TextField("Search foods and recipes", text: $query)
                .font(.system(size: 15))
                .focused($isSearchFieldFocused)

            if query.isEmpty {
                Button(action: {
                    guard !isOffline else { return }
                    step = .barcodeScanner
                }) {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignTokens.textTertiary)
                        .frame(width: 20, height: 20)
                }
                .disabled(isOffline)
                .opacity(isOffline ? 0.28 : 1)
            } else {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignTokens.backgroundElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSearchFieldFocused ? DesignTokens.accent : DesignTokens.border, lineWidth: isSearchFieldFocused ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: isSearchFieldFocused ? DesignTokens.accent.opacity(0.10) : .clear, radius: 6)
        .applyShadow1()
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.warningForeground)
            Text("Can't reach your server. Saved foods only.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DesignTokens.warningForeground)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(DesignTokens.warningBackground)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignTokens.warningBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var emptyStateContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("RECENT")
                resultList(Self.recentSamples)
            }

            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("FREQUENT")
                resultList(Self.frequentSamples)
            }
        }
    }

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            resultList(results)

            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14, weight: .medium))
                    Text("Add a custom food")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(DesignTokens.accent)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.08 * 11)
            .foregroundStyle(DesignTokens.textTertiary)
            .padding(.vertical, 2)
            .padding(.bottom, 10)
    }

    private func resultList(_ items: [FoodSearchResult]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
                }
                FoodResultRow(result: item, onTap: { select(item) })
            }
        }
        .background(DesignTokens.backgroundElevated)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DesignTokens.borderSoft, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func select(_ result: FoodSearchResult) {
        candidate = LogCandidate(result: result)
        // .quantity step lands in iOS-6; for now just confirm the candidate was captured.
        print("LogCandidate selected: \(candidate!)")
    }

    private func scheduleSearch(for newQuery: String) {
        searchTask?.cancel()
        guard !newQuery.isEmpty else {
            isLoading = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            isLoading = true
            do {
                let response = try await APIClient.shared.searchFoods(query: newQuery)
                guard !Task.isCancelled else { return }
                results = response
                isOffline = false
            } catch PorquiloAPIError.networkError(_), PorquiloAPIError.noServerConfigured {
                guard !Task.isCancelled else { return }
                isOffline = true
            } catch {
                guard !Task.isCancelled else { return }
                isOffline = true
            }
            isLoading = false
        }
    }
}

private struct FoodResultRow: View {
    let result: FoodSearchResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(result.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text(result.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(result.sourceName.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 7)
                    .background(DesignTokens.backgroundSunken)
                    .clipShape(Capsule())

                Text(result.calorieDisplay)
                    .font(.custom("Geist Mono", size: 11))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(result.isTopMatch ? DesignTokens.accentSoftBackground : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
