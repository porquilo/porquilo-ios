import SwiftUI

struct ModePickerSheet: View {
    let onQuickLogTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignTokens.borderStrong.opacity(0.4))
                .frame(width: 38, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)

            HStack(alignment: .top, spacing: 10) {
                Text("What did you eat?")
                    .font(.custom("Newsreader", size: 22))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineSpacing(22 * 0.15)

                Spacer()

                noScalePill
                    .layoutPriority(1)
            }
            .padding(.bottom, 4)

            Text("Pick how you'd like to log it.")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 18)

            weighItRow
                .padding(.bottom, 10)

            HStack(spacing: 10) {
                quickLogButton
                aiSupportedButton
            }
            .padding(.bottom, 14)

            Text("Your data. Your hardware. Nothing leaves this machine.")
                .font(.system(size: 11))
                .lineSpacing(11 * 0.55)
                .foregroundStyle(DesignTokens.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(DesignTokens.backgroundSunken)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(DesignTokens.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private var noScalePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DesignTokens.textMuted)
                .frame(width: 7, height: 7)
            Text("No scale")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(DesignTokens.background)
        .overlay(Capsule().stroke(DesignTokens.border, lineWidth: 1))
        .clipShape(Capsule())
        .fixedSize()
    }

    private var weighItRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "scalemass")
                .font(.system(size: 22))
                .foregroundStyle(DesignTokens.textMuted)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text("Weigh it")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignTokens.textTertiary)
                Text("Bluetooth scale — connect to enable")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.textMuted)
            }

            Spacer()

            confidenceBadge(label: "Measured", fg: DesignTokens.confidenceMeasuredFg, bg: DesignTokens.confidenceMeasuredBg)
                .opacity(0.5)
        }
        .padding(14)
        .background(DesignTokens.backgroundSunken)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DesignTokens.borderSoft, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var quickLogButton: some View {
        Button(action: onQuickLogTapped) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22))
                    .foregroundStyle(DesignTokens.accent)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick log")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("Search or scan a barcode")
                        .font(.system(size: 11))
                        .lineSpacing(11 * 0.4)
                        .foregroundStyle(DesignTokens.accentSoftForeground)
                }

                confidenceBadge(label: "Estimated", fg: DesignTokens.confidenceEstimatedFg, bg: DesignTokens.confidenceEstimatedBg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(DesignTokens.accentSoftBackground)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DesignTokens.accentSoftBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(DesignTokens.accent)
                    .frame(width: 7, height: 7)
                    .padding(10)
            }
        }
        .buttonStyle(.plain)
    }

    private var aiSupportedButton: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "camera")
                    .font(.system(size: 22))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI supported")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("Photo or plain language")
                        .font(.system(size: 11))
                        .lineSpacing(11 * 0.4)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                confidenceBadge(label: "Estimated", fg: DesignTokens.confidenceEstimatedFg, bg: DesignTokens.confidenceEstimatedBg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(DesignTokens.backgroundElevated)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DesignTokens.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func confidenceBadge(label: String, fg: Color, bg: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(fg)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(fg)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(bg)
        .clipShape(Capsule())
    }
}
