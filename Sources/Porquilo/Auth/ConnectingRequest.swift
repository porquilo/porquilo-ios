import Foundation

/// Drives the `.fullScreenCover` presentation of `ConnectingView`. Kept separate
/// from `AuthScreen` since Connecting overlays whichever screen triggered it
/// rather than replacing it.
struct ConnectingRequest: Identifiable {
    let id = UUID()
    let serverURL: URL
    let operation: () async throws -> (token: String, user: User)
    let onSuccess: (String, String) -> Void
    let onFailure: (PorquiloAPIError) -> Void
}
