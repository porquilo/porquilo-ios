import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(DesignTokens.accentSoftBackground)
                    .frame(width: 72, height: 72)
                    .overlay(LogoMarkView(size: 32))

                Text("Porquilo")
                    .font(.porqDisplay)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .tracking(-0.025 * 38)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)

                Text("Your private nutrition tracker.")
                    .font(.porqBody)
                    .foregroundStyle(DesignTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }

            Spacer()

            VStack(spacing: 18) {
                Text("YOUR DATA. YOUR HARDWARE.")
                    .font(.porqCaption)
                    .foregroundStyle(DesignTokens.textMuted)
                    .textCase(.uppercase)

                Button(action: onGetStarted) {
                    Text("Get started")
                        .font(.porqBody.weight(.semibold))
                        .foregroundStyle(DesignTokens.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 28).fill(DesignTokens.accent))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background)
    }
}
