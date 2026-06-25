import SwiftUI

struct ReportsView: View {
    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack {
                Spacer()
                Text("Reports")
                    .font(.porqBody)
                    .foregroundStyle(DesignTokens.textTertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
