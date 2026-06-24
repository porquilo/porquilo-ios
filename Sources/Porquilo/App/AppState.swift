import Foundation

@Observable
final class AppState {
    var isAuthenticated: Bool
    var currentUser: User?

    init() {
        let token = KeychainService.load()
        self.isAuthenticated = token != nil
    }
}
