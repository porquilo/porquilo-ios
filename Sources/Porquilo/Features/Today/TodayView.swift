import SwiftUI

enum DiaryLoadState {
    case loading
    case loaded(DiaryDay)
    case failed
}

struct TodayView: View {
    @State private var displayedDate: Date = Date()
    @State private var showModePicker: Bool = false
    @State private var showQuickLog: Bool = false
    @State private var loadState: DiaryLoadState = .loading

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DesignTokens.background.ignoresSafeArea()

            VStack(spacing: 0) {
                dateHeader

                content
            }

            fab
        }
        .task(id: displayedDate) { await loadDiary() }
        .sheet(isPresented: $showModePicker) {
            ModePickerSheet(onQuickLogTapped: {
                showModePicker = false
                showQuickLog = true
            })
        }
        .fullScreenCover(isPresented: $showQuickLog) {
            QuickLogView(
                onDismiss: { showQuickLog = false },
                onLogged: { Task { await loadDiary() } }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tint(DesignTokens.accent)

        case .loaded(let diary):
            ScrollView {
                VStack(spacing: 16) {
                    MacroBarView(total: diary.macroTotal)

                    ForEach(diary.meals) { section in
                        MealSectionView(section: section, onAddFood: { showModePicker = true })
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 130)
            }

        case .failed:
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundStyle(DesignTokens.textMuted)
                Text("Couldn't load diary.")
                    .font(Font.porqBody)
                    .foregroundStyle(DesignTokens.textSecondary)
                Button("Try again") { Task { await loadDiary() } }
                    .font(Font.porqBody)
                    .foregroundStyle(DesignTokens.accent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var dateHeader: some View {
        HStack {
            Button(action: { displayedDate = Calendar.current.date(byAdding: .day, value: -1, to: displayedDate) ?? displayedDate }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            VStack(spacing: 3) {
                Text(formattedDate)
                    .font(.custom("Newsreader", size: 19))
                    .tracking(-0.01 * 19)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineSpacing(0)

                Text(relativeDayLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.08 * 10)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.textTertiary)
            }

            Spacer()

            Button(action: { displayedDate = Calendar.current.date(byAdding: .day, value: 1, to: displayedDate) ?? displayedDate }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 56)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.borderSoft)
                .frame(height: 1)
        }
    }

    private var fab: some View {
        Button(action: { showModePicker = true }) {
            RoundedRectangle(cornerRadius: 18)
                .fill(DesignTokens.accent)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DesignTokens.textOnAccent)
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(DesignTokens.textMuted)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(DesignTokens.accent, lineWidth: 2.5))
                        .offset(x: 2, y: -2)
                }
                .shadow(color: DesignTokens.accent.opacity(0.42), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 110)
    }

    private func loadDiary() async {
        loadState = .loading
        do {
            let diary = try await APIClient.shared.fetchDiary(for: displayedDate)
            loadState = .loaded(diary)
        } catch {
            print("TodayView.loadDiary failed: \(error)")
            loadState = .failed
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: displayedDate)
    }

    private var relativeDayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(displayedDate) {
            return "Today"
        }
        if calendar.isDateInYesterday(displayedDate) {
            return "Yesterday"
        }
        if calendar.isDateInTomorrow(displayedDate) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: displayedDate)
    }
}
