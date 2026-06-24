import Foundation

@Observable
final class AppState {
    var isAuthenticated: Bool
    var currentUser: User?
    var showVersionWarning = false
    private(set) var serverVersion: String?

    init(tokenLoader: () -> String? = KeychainService.load) {
        self.isAuthenticated = tokenLoader() != nil
    }

    func completeAuth(token: String, serverURL: String) {
        _ = KeychainService.save(token: token)
        UserDefaults.standard.set(serverURL, forKey: AppConstants.serverURLKey)
        isAuthenticated = true
    }

    func signOut() {
        _ = KeychainService.delete()
        UserDefaults.standard.removeObject(forKey: AppConstants.serverURLKey)
        isAuthenticated = false
        currentUser = nil
    }

    func checkServerVersion() async {
        guard let version = try? await APIClient.shared.fetchServerVersion() else { return }
        serverVersion = version
        if !Self.isVersionSufficient(version, minimum: AppConstants.minimumServerVersion) {
            showVersionWarning = true
        }
    }

    static func isVersionSufficient(_ version: String, minimum: String) -> Bool {
        let v = version.split(separator: ".").compactMap { Int($0) }
        let m = minimum.split(separator: ".").compactMap { Int($0) }
        guard v.count == 3, m.count == 3 else { return true }
        if v[0] != m[0] { return v[0] > m[0] }
        if v[1] != m[1] { return v[1] > m[1] }
        return v[2] >= m[2]
    }
}
