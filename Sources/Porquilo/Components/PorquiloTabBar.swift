import SwiftUI

struct PorquiloTabBar: View {
    @Binding var selectedTab: PorquiloTab

    var body: some View {
        HStack {
            ForEach(PorquiloTab.allCases, id: \.self) { tab in
                Spacer()
                tabButton(for: tab)
                Spacer()
            }
        }
        .frame(height: 64)
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(DesignTokens.borderSoft, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: DesignTokens.shadowColor.opacity(0.14), radius: 24, y: 8)
    }

    private func tabButton(for tab: PorquiloTab) -> some View {
        let isSelected = tab == selectedTab
        let color = isSelected ? DesignTokens.accent : DesignTokens.textMuted

        return Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 22))
                    .foregroundStyle(color)

                Text(tab.label)
                    .font(.porqCaption.weight(.semibold))
                    .tracking(0.02 * 10)
                    .foregroundStyle(color)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
    }
}

extension PorquiloTab {
    var symbolName: String {
        switch self {
        case .today: "house"
        case .library: "doc.text"
        case .reports: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }

    var label: String {
        switch self {
        case .today: "Today"
        case .library: "Library"
        case .reports: "Reports"
        case .settings: "Settings"
        }
    }
}
