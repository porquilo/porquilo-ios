import Foundation

enum AuthScreen: Equatable {
    case welcome
    case connect
    case qrScanner
    case qrError(QRErrorType)
    case manualEntry
}

enum QRErrorType: Equatable {
    case expired
    case alreadyUsed
}

/// Owns the auth flow's current screen. Held via `@State` on `AuthRootView`
/// (the single source of truth) per the flat screen-machine navigation model —
/// there is no `NavigationStack`; back-navigation is a direct screen assignment.
@Observable
final class AuthNavigationState {
    var screen: AuthScreen = .welcome
}
