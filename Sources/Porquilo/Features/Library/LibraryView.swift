import SwiftUI

struct LibraryView: View {
    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            VStack {
                Spacer()
                Text("Library")
                    .font(.porqBody)
                    .foregroundStyle(DesignTokens.textTertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
