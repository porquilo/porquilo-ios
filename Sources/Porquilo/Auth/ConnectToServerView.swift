import SwiftUI

struct ConnectToServerView: View {
    let onBack: () -> Void
    let onScanQR: () -> Void
    let onManualEntry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backButton

            VStack(alignment: .leading, spacing: 0) {
                Text("Connect to your server")
                    .font(.porqHeading)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(.top, 6)

                Text("You've been added by an admin. Connect your phone to start logging.")
                    .font(.custom("Geist", size: 14, relativeTo: .body))
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.top, 10)

                qrCard
                    .padding(.top, 28)

                dividerRow
                    .padding(.top, 20)

                Button(action: onManualEntry) {
                    Text("Enter server address manually")
                        .font(.custom("Geist", size: 15, relativeTo: .body))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.background)
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .foregroundStyle(DesignTokens.accent)
                .frame(width: 44, height: 44)
        }
        .padding(.leading, 8)
    }

    private var qrCard: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.accentSoftBackground)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "qrcode")
                        .foregroundStyle(DesignTokens.accent)
                )

            Button(action: onScanQR) {
                Text("Scan QR code")
                    .font(.porqBody.weight(.semibold))
                    .foregroundStyle(DesignTokens.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 14).fill(DesignTokens.accent))
            }

            Text("Your admin generates a QR code from the web dashboard. Open it on their screen and scan it here.")
                .font(.custom("Geist", size: 13, relativeTo: .body))
                .foregroundStyle(DesignTokens.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.backgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(DesignTokens.border, lineWidth: 1))
        )
        .applyShadow2()
    }

    private var dividerRow: some View {
        HStack {
            Rectangle().fill(DesignTokens.border).frame(height: 1)
            Text("or")
                .font(.porqCaption)
                .foregroundStyle(DesignTokens.textMuted)
            Rectangle().fill(DesignTokens.border).frame(height: 1)
        }
    }
}
