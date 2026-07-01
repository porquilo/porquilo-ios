import SwiftUI

struct MealTimePickerSheet: View {
    let meals: [Meal]
    @Binding var selectedMeal: Meal?
    @Binding var eatenAt: Date
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingTime: Bool = false
    @State private var timeText: String = ""
    @State private var timeFieldShakeOffset: CGFloat = 0
    @FocusState private var isTimeFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(DesignTokens.borderStrong.opacity(0.4))
                .frame(width: 38, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 18)

            Text("Adding to")
                .font(.custom("Newsreader", size: 21))
                .tracking(-0.01 * 21)
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(.bottom, 16)

            mealChips
                .padding(.bottom, 22)

            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
                .padding(.bottom, 20)

            HStack {
                Text("WHEN?")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.08 * 12)
                    .foregroundStyle(DesignTokens.textTertiary)
                Spacer()
                Text("Estimated — no scale used")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundStyle(DesignTokens.textMuted)
            }
            .padding(.bottom, 12)

            timeBlock

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignTokens.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(DesignTokens.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: DesignTokens.accent.opacity(0.28), radius: 8, y: 4)
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(DesignTokens.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var mealChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(meals) { meal in
                    Button(action: { selectedMeal = meal }) {
                        Text(meal.name)
                            .font(.system(size: 14, weight: selectedMeal == meal ? .semibold : .medium))
                            .foregroundStyle(selectedMeal == meal ? DesignTokens.textOnAccent : DesignTokens.textSecondary)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 16)
                            .background(selectedMeal == meal ? DesignTokens.accent : DesignTokens.backgroundSunken)
                            .overlay {
                                if selectedMeal != meal {
                                    Capsule().stroke(DesignTokens.border, lineWidth: 1)
                                }
                            }
                            .clipShape(Capsule())
                            .shadow(color: selectedMeal == meal ? DesignTokens.accent.opacity(0.25) : .clear, radius: 6, y: 2)
                    }
                }

                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 13))
                        .foregroundStyle(DesignTokens.textTertiary)
                        .frame(width: 38, height: 38)
                        .background(DesignTokens.backgroundSunken)
                        .overlay(Circle().stroke(DesignTokens.borderStrong, lineWidth: 1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
        .overlay(alignment: .trailing) {
            LinearGradient(
                colors: [.clear, DesignTokens.background],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 32)
            .allowsHitTesting(false)
        }
    }

    private var timeBlock: some View {
        VStack(spacing: 14) {
            HStack {
                timeShiftButton(systemName: "chevron.left", label: "EARLIER") {
                    eatenAt = Calendar.current.date(byAdding: .minute, value: -30, to: eatenAt) ?? eatenAt
                }

                Spacer()

                VStack(spacing: 2) {
                    if isEditingTime {
                        TextField("", text: $timeText)
                            .font(.custom("Geist Mono", size: 44))
                            .fontWeight(.medium)
                            .tracking(-0.025 * 44)
                            .foregroundStyle(DesignTokens.textPrimary)
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($isTimeFieldFocused)
                            .frame(width: 120)
                            .offset(x: timeFieldShakeOffset)
                            .onSubmit { commitTimeEdit() }
                            .onAppear {
                                timeText = formatTime(eatenAt)
                                isTimeFieldFocused = true
                            }

                        Button("Cancel") {
                            isEditingTime = false
                            timeText = ""
                            timeFieldShakeOffset = 0
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(DesignTokens.textMuted)
                    } else {
                        Text(formatTime(eatenAt))
                            .font(.custom("Geist Mono", size: 44))
                            .fontWeight(.medium)
                            .tracking(-0.025 * 44)
                            .foregroundStyle(DesignTokens.textPrimary)
                            .monospacedDigit()
                            .contentShape(Rectangle())
                            .onTapGesture { isEditingTime = true }

                        Text(naturalLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }

                Spacer()

                timeShiftButton(systemName: "chevron.right", label: "LATER") {
                    eatenAt = Calendar.current.date(byAdding: .minute, value: 30, to: eatenAt) ?? eatenAt
                }
            }

            HStack(spacing: 6) {
                fineAdjustButton(label: "−15 min", minutes: -15)
                fineAdjustButton(label: "−1 hr", minutes: -60)
                fineAdjustButton(label: "+1 hr", minutes: 60)
                fineAdjustButton(label: "+15 min", minutes: 15)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(DesignTokens.backgroundSunken)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DesignTokens.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func timeShiftButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 20))
                    .foregroundStyle(DesignTokens.textSecondary)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.07 * 10)
                    .foregroundStyle(DesignTokens.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private func fineAdjustButton(label: String, minutes: Int) -> some View {
        Button(action: {
            eatenAt = Calendar.current.date(byAdding: .minute, value: minutes, to: eatenAt) ?? eatenAt
        }) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(DesignTokens.backgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DesignTokens.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ date: Date) -> String {
        let h = Calendar.current.component(.hour, from: date)
        let m = Calendar.current.component(.minute, from: date)
        return String(format: "%d:%02d", h, m)
    }

    private func commitTimeEdit() {
        let parts = timeText.split(separator: ":").map(String.init)
        guard parts.count == 2,
              let h = Int(parts[0]), h >= 0, h <= 23,
              let m = Int(parts[1]), m >= 0, m <= 59
        else {
            shakeTimeField()
            return
        }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: eatenAt)
        comps.hour = h
        comps.minute = m
        if let updated = Calendar.current.date(from: comps) {
            eatenAt = updated
        }
        isEditingTime = false
        timeText = ""
    }

    private func shakeTimeField() {
        withAnimation(.easeInOut(duration: 0.06).repeatCount(4, autoreverses: true)) {
            timeFieldShakeOffset = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            timeFieldShakeOffset = 0
        }
    }

    private var naturalLabel: String {
        let hour = Calendar.current.component(.hour, from: eatenAt)
        switch hour {
        case 5..<12: return "this morning"
        case 12..<17: return "this afternoon"
        case 17..<21: return "this evening"
        default: return "today"
        }
    }
}
