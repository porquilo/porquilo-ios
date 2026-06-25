import SwiftUI

enum PorquiloTab: CaseIterable {
    case today, library, reports, settings
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: PorquiloTab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .today:
                    TodayView()
                case .library:
                    LibraryView()
                case .reports:
                    ReportsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PorquiloTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
        }
        .ignoresSafeArea(edges: .bottom)
        .task { await appState.checkServerVersion() }
        .sheet(isPresented: Bindable(appState).showVersionWarning) {
            VersionWarningSheet()
        }
    }
}
