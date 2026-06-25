import SwiftUI

struct QRErrorView: View {
    let reason: QRErrorType
    let onBack: () -> Void
    let onScanAgain: () -> Void
    let onEnterManually: () -> Void

    private var badgeText: String {
        switch reason {
        case .expired: return "Expired"
        case .alreadyUsed: return "Already used"
        }
    }

    private var title: String {
        switch reason {
        case .expired: return "Code expired"
        case .alreadyUsed: return "Code already used"
        }
    }

    private var description: String {
        switch reason {
        case .expired: return "This code is more than 15 minutes old."
        case .alreadyUsed: return "This code has already been used to sign in."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(DesignTokens.accent)
                        .frame(width: 44, height: 44)
                }
                .padding(.leading, 8)
                Spacer()
            }

            Spacer()

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(badgeText)
                        .font(.porqCaption)
                }
                .foregroundStyle(DesignTokens.dangerForeground)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(DesignTokens.dangerBackground))

                Text(title)
                    .font(.porqHeading)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(.top, 22)

                Text(description)
                    .font(.custom("Geist", size: 15, relativeTo: .body))
                    .foregroundStyle(DesignTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                Text("Ask your admin to generate a new one.")
                    .font(.custom("Geist", size: 15, relativeTo: .body))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                Button(action: onScanAgain) {
                    Text("Scan again")
                        .font(.porqBody.weight(.semibold))
                        .foregroundStyle(DesignTokens.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(DesignTokens.accent))
                }

                Button(action: onEnterManually) {
                    Text("Enter manually")
                        .font(.custom("Geist", size: 15, relativeTo: .body))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background)
    }
}
