import SwiftUI

struct AuthRootView: View {
    @Environment(AppState.self) private var appState

    @State private var nav = AuthNavigationState()
    @State private var connectingRequest: ConnectingRequest?
    @State private var manualEntryError: PorquiloAPIError?
    @State private var qrScannerError: PorquiloAPIError?

    var body: some View {
        Group {
            switch nav.screen {
            case .welcome:
                WelcomeView(onGetStarted: { nav.screen = .connect })
            case .connect:
                ConnectToServerView(
                    onBack: { nav.screen = .welcome },
                    onScanQR: { nav.screen = .qrScanner },
                    onManualEntry: { nav.screen = .manualEntry }
                )
            case .qrScanner:
                QRScannerView(
                    onCancel: { nav.screen = .connect },
                    onScanSuccess: startPairingExchange,
                    connectingError: $qrScannerError
                )
            case .qrError(let reason):
                QRErrorView(
                    reason: reason,
                    onBack: { nav.screen = .qrScanner },
                    onScanAgain: { nav.screen = .qrScanner },
                    onEnterManually: { nav.screen = .manualEntry }
                )
            case .manualEntry:
                ManualEntryView(
                    onBack: { nav.screen = .connect },
                    onSubmit: startLogin,
                    connectingError: $manualEntryError
                )
            }
        }
        .fullScreenCover(item: $connectingRequest) { request in
            ConnectingView(
                serverURL: request.serverURL,
                operation: request.operation,
                onSuccess: request.onSuccess,
                onFailure: request.onFailure
            )
        }
    }

    private func startLogin(serverURL: URL, username: String, password: String) {
        connectingRequest = ConnectingRequest(
            serverURL: serverURL,
            operation: { try await APIClient.shared.login(serverURL: serverURL, username: username, password: password) },
            onSuccess: { token, urlString in
                connectingRequest = nil
                appState.completeAuth(token: token, serverURL: urlString)
            },
            onFailure: { error in
                connectingRequest = nil
                manualEntryError = error
            }
        )
    }

    private func startPairingExchange(serverURL: URL, code: String) {
        connectingRequest = ConnectingRequest(
            serverURL: serverURL,
            operation: { try await APIClient.shared.exchangePairingCode(code, serverURL: serverURL) },
            onSuccess: { token, urlString in
                connectingRequest = nil
                appState.completeAuth(token: token, serverURL: urlString)
            },
            onFailure: { error in
                connectingRequest = nil
                // ASSUMPTION: the server distinguishes these two pairing failure
                // modes via distinct error codes — confirm against the real
                // server contract. Anything else falls back to an inline
                // "Couldn't read that code" message on QRScannerView.
                if case .serverError(let code, _) = error, code == "pairing_code_expired" {
                    nav.screen = .qrError(.expired)
                } else if case .serverError(let code, _) = error, code == "pairing_code_already_used" {
                    nav.screen = .qrError(.alreadyUsed)
                } else {
                    qrScannerError = error
                }
            }
        )
    }
}
