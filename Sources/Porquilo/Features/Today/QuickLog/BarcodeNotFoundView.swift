import SwiftUI

struct BarcodeNotFoundView: View {
    let barcode: String
    @Binding var step: QuickLogStep
    let onDismiss: () -> Void

    private let scannedAt = Date()

    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                VStack(spacing: 0) {
                    Spacer().frame(height: 44)

                    barcodeIllustration
                        .padding(.bottom, 28)

                    Text("This barcode isn't in your library yet.")
                        .font(.custom("Newsreader", size: 23))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineSpacing(23 * 0.3)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)

                    Text("Open Food Facts didn't recognize it either.")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.textTertiary)
                        .lineSpacing(14 * 0.6)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 36)

                    Button(action: {}) {
                        Text("Add this food")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DesignTokens.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(DesignTokens.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: DesignTokens.accent.opacity(0.28), radius: 8, y: 4)
                    }
                    .padding(.bottom, 10)

                    Button(action: { step = .search }) {
                        Text("Search manually")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DesignTokens.border, lineWidth: 1))
                    }

                    Spacer()

                    Text("Scanned at \(formattedTime)")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 44)
            }
        }
    }

    private var navBar: some View {
        ZStack {
            Text("Not found")
                .font(.custom("Newsreader", size: 18))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack {
                Button(action: { step = .barcodeScanner }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("Scan")
                            .font(.system(size: 14, weight: .medium))
                    }
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
        .frame(height: 50)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.borderSoft).frame(height: 1)
        }
    }

    private var barcodeIllustration: some View {
        VStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(Array(barWidths.enumerated()), id: \.offset) { _, width in
                    Rectangle()
                        .fill(DesignTokens.textPrimary.opacity(0.45))
                        .frame(width: width, height: 64)
                }
            }

            Text(barcode)
                .font(.custom("Geist Mono", size: 12))
                .foregroundStyle(DesignTokens.textTertiary)
                .tracking(0.14 * 12)
        }
    }

    private var barWidths: [CGFloat] {
        (0..<20).map { index in
            [2.0, 4.0, 2.0, 3.0, 5.0, 2.0][index % 6]
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scannedAt)
    }
}
