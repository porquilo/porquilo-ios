import SwiftUI

struct LogEntryRowView: View {
    let entry: DiaryLogEntry

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(entry.timeString)
                .font(.custom("Geist Mono", size: 11))
                .foregroundStyle(DesignTokens.textTertiary)
                .frame(width: 40, alignment: .leading)

            HStack(spacing: 7) {
                Circle()
                    .fill(entry.isEstimated ? DesignTokens.confidenceEstimatedDot : DesignTokens.confidenceMeasuredDot)
                    .frame(width: 7, height: 7)
                Text(entry.foodName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .lastTextBaseline, spacing: 7) {
                if let weightG = entry.weightG {
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text("\(Int(weightG))")
                            .font(.custom("Geist Mono", size: 12))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text("g")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }
                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(Int(entry.calories))")
                        .font(.custom("Geist Mono", size: 12))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("kcal")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(DesignTokens.backgroundElevated)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignTokens.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .applyShadow1()
    }
}
