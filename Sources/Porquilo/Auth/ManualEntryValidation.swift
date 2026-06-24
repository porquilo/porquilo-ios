import Foundation

enum ManualEntryValidation {
    struct Result {
        var urlError: String?
        var credError: String?
    }

    /// Runs the manual-entry form's validation in spec order. Stops at the first
    /// failure (matches the UI's one-error-at-a-time behavior).
    static func validate(url: String, username: String, password: String) -> Result {
        if url.isEmpty {
            return Result(urlError: "Enter your server address.")
        }
        if !(url.hasPrefix("http://") || url.hasPrefix("https://")) {
            return Result(urlError: "Address must start with https:// or http://")
        }
        if username.isEmpty {
            return Result(credError: "Username is required.")
        }
        if password.isEmpty {
            return Result(credError: "Password is required.")
        }
        return Result()
    }
}
