import SwiftUI
import SwiftData

@main
struct PorquiloApp: App {
    @State private var appState = AppState()
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Schema([]))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(modelContainer)
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isAuthenticated {
            MainTabView()
        } else {
            AuthRootView()
        }
    }
}
