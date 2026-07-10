import SwiftUI

struct EditLogEntryView: View {
    let entry: DiaryLogEntry
    let onSaved: () -> Void
    let onDeleted: () -> Void
    let onDismiss: () -> Void
    @Environment(AppState.self) private var appState

    /// `weight_source` isn't on the diary list — only `GET /api/entries/{id}` carries
    /// it (see `APIClient.fetchLogEntry`) — so the view fetches it on open and can't
    /// safely allow Save until it knows which value it started from.
    private enum DetailLoadState {
        case loading
        case loaded(weightSource: String)
        case failed

        var isLoaded: Bool {
            if case .loaded = self { return true }
            return false
        }
    }

    @State private var detailState: DetailLoadState = .loading
    @State private var quantityText: String
    @State private var originalQuantityText: String
    @State private var eatenAt: Date
    @State private var quantityError: String?
    @State private var apiError: String?
    @State private var isSubmitting: Bool = false
    @State private var showDeleteConfirm: Bool = false

    init(entry: DiaryLogEntry, onSaved: @escaping () -> Void, onDeleted: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.entry = entry
        self.onSaved = onSaved
        self.onDeleted = onDeleted
        self.onDismiss = onDismiss
        let initialQuantityText = Self.formatQuantity(entry.quantityG)
        self._quantityText = State(initialValue: initialQuantityText)
        self._originalQuantityText = State(initialValue: initialQuantityText)
        self._eatenAt = State(initialValue: entry.eatenAt)
    }

    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        foodNameSection

                        quantitySection

                        timeSection

                        if showsEstimatedDemotionWarning {
                            Text("Editing this value marks the entry as Estimated.")
                                .font(.system(size: 12))
                                .foregroundStyle(DesignTokens.dangerForeground)
                        }

                        if let apiError {
                            apiErrorBanner(apiError)
                        }

                        deleteButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .task { await loadDetail() }
        .confirmationDialog(
            "Delete entry?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete \(entry.foodName)", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text("Edit entry")
                .font(.custom("Newsreader", size: 18))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack {
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                Button(action: save) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Save")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .foregroundStyle(DesignTokens.accent)
                .disabled(isSubmitting || quantityError != nil || !detailState.isLoaded)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
        }
    }

    // MARK: - Food name + confidence badge

    private var foodNameSection: some View {
        HStack {
            Text(entry.foodName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DesignTokens.textPrimary)

            Spacer()

            confidenceBadge
        }
    }

    @ViewBuilder
    private var confidenceBadge: some View {
        switch detailState {
        case .loading:
            ProgressView()
        case .failed:
            EmptyView()
        case .loaded(let weightSource):
            let isMeasured = weightSource == "scale"
            Text(isMeasured ? "Measured" : "Estimated")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isMeasured ? DesignTokens.confidenceMeasuredFg : DesignTokens.confidenceEstimatedFg)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(isMeasured ? DesignTokens.confidenceMeasuredBg : DesignTokens.confidenceEstimatedBg)
                .clipShape(Capsule())
        }
    }

    // MARK: - Quantity field

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Quantity (g)")
            fieldContainer(isError: quantityError != nil) {
                TextField("", text: $quantityText)
                    .font(.system(size: 14))
                    .keyboardType(.decimalPad)
                    .onChange(of: quantityText) { _, _ in quantityError = nil }
            }
            if let quantityError {
                errorRow(quantityError)
            }
        }
    }

    // MARK: - Time field

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Time")
            DatePicker("", selection: $eatenAt, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(action: { showDeleteConfirm = true }) {
            Text("Delete entry")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DesignTokens.dangerForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Shared field styling (matches CreateCustomFoodView)

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

    // MARK: - Derived state

    private var showsEstimatedDemotionWarning: Bool {
        guard case .loaded(let weightSource) = detailState else { return false }
        return weightSource == "scale" && quantityText != originalQuantityText
    }

    private static func formatQuantity(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    // MARK: - Networking

    private func loadDetail() async {
        do {
            let detail = try await APIClient.shared.fetchLogEntry(id: entry.id)
            eatenAt = detail.eatenAt
            let text = Self.formatQuantity(detail.quantityG)
            quantityText = text
            originalQuantityText = text
            detailState = .loaded(weightSource: detail.weightSource)
        } catch PorquiloAPIError.unauthorized {
            appState.signOut()
        } catch {
            detailState = .failed
        }
    }

    private func save() {
        quantityError = EditLogEntryValidation.validate(quantityText: quantityText)
        guard quantityError == nil,
              case .loaded(let weightSource) = detailState,
              let quantityValue = Double(quantityText)
        else { return }

        let weightSourceToSend = EditLogEntryValidation.weightSourceToSend(
            originalWeightSource: weightSource,
            quantityChanged: quantityText != originalQuantityText
        )

        isSubmitting = true
        apiError = nil

        Task {
            do {
                try await APIClient.shared.updateLogEntry(
                    id: entry.id,
                    quantityG: quantityValue,
                    eatenAt: eatenAt,
                    weightSource: weightSourceToSend
                )
                isSubmitting = false
                onSaved()
            } catch PorquiloAPIError.unauthorized {
                isSubmitting = false
                appState.signOut()
            } catch {
                isSubmitting = false
                apiError = error.localizedDescription
            }
        }
    }

    private func delete() {
        Task {
            do {
                try await APIClient.shared.deleteLogEntry(id: entry.id)
                onDeleted()
            } catch PorquiloAPIError.unauthorized {
                appState.signOut()
            } catch {
                apiError = error.localizedDescription
            }
        }
    }
}
