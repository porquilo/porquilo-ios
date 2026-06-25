import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack {
                Spacer()
                Text("Settings")
                    .font(.porqBody)
                    .foregroundStyle(DesignTokens.textTertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
