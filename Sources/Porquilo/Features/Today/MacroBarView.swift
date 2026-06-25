import SwiftUI

struct MacroBarView: View {
    let total: MacroTotal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY, EATEN")
                .font(.porqCaption.weight(.semibold))
                .tracking(0.08 * 11)
                .foregroundStyle(DesignTokens.textTertiary)
                .padding(.bottom, 8)

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                if total.isEstimated {
                    Text("~")
                        .font(.porqMono.weight(.medium))
                        .foregroundStyle(DesignTokens.confidenceEstimatedFg)
                }
                Text("\(Int(total.calories))")
                    .font(.custom("Geist Mono", size: 36).weight(.medium))
                    .tracking(-0.025 * 36)
                    .foregroundStyle(total.isEstimated ? DesignTokens.confidenceEstimatedFg : DesignTokens.textPrimary)
                Text("kcal")
                    .font(.porqSmall)
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.leading, 2)
            }
            .padding(.bottom, 10)

            GeometryReader { geometry in
                let total3 = max(total.proteinG + total.carbsG + total.fatG, 1)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(DesignTokens.herb500)
                        .frame(width: geometry.size.width * total.proteinG / total3)
                    Rectangle()
                        .fill(DesignTokens.honey500)
                        .frame(width: geometry.size.width * total.carbsG / total3)
                    Rectangle()
                        .fill(DesignTokens.clay500)
                        .frame(width: geometry.size.width * total.fatG / total3)
                }
            }
            .frame(height: 7)
            .background(DesignTokens.backgroundSunken)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.bottom, 10)

            HStack(spacing: 14) {
                macroChip(color: DesignTokens.herb500, label: "Protein", value: total.proteinG)
                macroChip(color: DesignTokens.honey500, label: "Carbs", value: total.carbsG)
                macroChip(color: DesignTokens.clay500, label: "Fat", value: total.fatG)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(DesignTokens.backgroundElevated)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(DesignTokens.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .applyShadow2()
    }

    private func macroChip(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.textSecondary)
            Text("\(Int(value))g")
                .font(.custom("Geist Mono", size: 11).weight(.medium))
                .foregroundStyle(DesignTokens.textPrimary)
        }
    }
}
