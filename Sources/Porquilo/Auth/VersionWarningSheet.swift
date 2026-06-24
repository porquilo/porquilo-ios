import SwiftUI

struct VersionWarningSheet: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Server update recommended")
                .font(.porqHeading)
                .foregroundStyle(DesignTokens.textPrimary)

            Text(
                "This app works best with server v\(AppConstants.minimumServerVersion) or newer. " +
                "Your server is running v\(appState.serverVersion ?? "unknown")."
            )
            .font(.porqBody)
            .foregroundStyle(DesignTokens.textSecondary)

            Button(action: { appState.showVersionWarning = false }) {
                Text("Dismiss")
                    .font(.porqBody.weight(.semibold))
                    .foregroundStyle(DesignTokens.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 14).fill(DesignTokens.accent))
            }
        }
        .padding(24)
    }
}
