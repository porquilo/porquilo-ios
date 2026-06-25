import SwiftUI

struct TodayView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DesignTokens.background.ignoresSafeArea()

            VStack {
                Spacer()
                Text("Today")
                    .font(.porqBody)
                    .foregroundStyle(DesignTokens.textTertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // FAB stub — inert, no tap action
            RoundedRectangle(cornerRadius: 18)
                .fill(DesignTokens.accent)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DesignTokens.textOnAccent)
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(DesignTokens.textMuted)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(DesignTokens.accent, lineWidth: 2.5))
                        .offset(x: 2, y: -2)
                }
                .shadow(color: DesignTokens.accent.opacity(0.42), radius: 12, y: 5)
                .padding(.trailing, 20)
                .padding(.bottom, 110)
        }
    }
}
