import SwiftUI

struct MealSectionView: View {
    let section: MealSection
    let onAddFood: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(section.name)
                    .font(.custom("Newsreader", size: 18))
                    .italic()
                    .tracking(-0.01 * 18)
                    .foregroundStyle(section.entries.isEmpty ? DesignTokens.textTertiary : DesignTokens.textPrimary)

                Spacer()

                if !section.entries.isEmpty {
                    HStack(spacing: 2) {
                        if section.isEstimated {
                            Text("~")
                        }
                        Text("\(Int(section.totalCalories)) kcal")
                    }
                    .font(.custom("Geist Mono", size: 11))
                    .foregroundStyle(DesignTokens.confidenceEstimatedFg)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(DesignTokens.borderSoft)
                    .frame(height: 1)
            }

            if section.entries.isEmpty {
                let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
                LazyVGrid(columns: columns, spacing: 8) {
                    dashedButton(systemImage: "plus", label: "Add food", action: onAddFood)
                    dashedButton(systemImage: "xmark", label: "Not eating", action: {})
                }
            } else {
                ForEach(section.entries) { entry in
                    LogEntryRowView(entry: entry)
                }
            }
        }
    }

    private func dashedButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 14, height: 14)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(DesignTokens.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(DesignTokens.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}
