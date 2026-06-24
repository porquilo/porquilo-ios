import Foundation

@Observable
final class AppState {
    var isAuthenticated: Bool
    var currentUser: User?

    init(tokenLoader: () -> String? = KeychainService.load) {
        self.isAuthenticated = tokenLoader() != nil
    }
}
