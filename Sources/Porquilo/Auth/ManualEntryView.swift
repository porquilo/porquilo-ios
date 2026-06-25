import SwiftUI

struct ManualEntryView: View {
    let onBack: () -> Void
    /// Called once local validation passes — AuthRootView owns presenting the
    /// Connecting cover and routing any failure back via `connectingError`.
    let onSubmit: (URL, String, String) -> Void
    @Binding var connectingError: PorquiloAPIError?

    @State private var serverURLText = ""
    @State private var username = ""
    @State private var password = ""
    @State private var urlError: String?
    @State private var credError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(DesignTokens.accent)
                        .frame(width: 44, height: 44)
                }
                .padding(.leading, 8)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Connect manually")
                    .font(.porqHeading)
                    .foregroundStyle(DesignTokens.textPrimary)

                Text("Enter the address your admin shared with you.")
                    .font(.custom("Geist", size: 14, relativeTo: .body))
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.top, 10)

                serverAddressField
                    .padding(.top, 24)

                fieldContainer(isError: credError != nil) {
                    TextField("", text: $username, prompt: Text("your-username").foregroundStyle(DesignTokens.textMuted))
                        .font(.custom("Geist", size: 15, relativeTo: .body))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.top, 16)

                fieldContainer(isError: credError != nil) {
                    SecureField("", text: $password, prompt: Text("••••••••").foregroundStyle(DesignTokens.textMuted))
                        .font(.custom("Geist", size: 15, relativeTo: .body))
                }
                .padding(.top, 12)

                if let credError {
                    errorRow(credError).padding(.top, 8)
                }

                Button(action: submit) {
                    Text("Connect")
                        .font(.porqBody.weight(.semibold))
                        .foregroundStyle(DesignTokens.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(DesignTokens.accent))
                }
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignTokens.background)
        .onChange(of: connectingError) { _, newValue in
            guard let newValue else { return }
            applyConnectingFailure(newValue)
            connectingError = nil
        }
    }

    private var serverAddressField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SERVER ADDRESS")
                .font(.porqCaption)
                .foregroundStyle(DesignTokens.textTertiary)
                .textCase(.uppercase)

            fieldContainer(isError: urlError != nil) {
                TextField(
                    "",
                    text: $serverURLText,
                    prompt: Text("https://nutrition.home.local").foregroundStyle(DesignTokens.textMuted)
                )
                .font(.custom("Geist Mono", size: 14, relativeTo: .body))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }

            if let urlError {
                errorRow(urlError)
            }
        }
    }

    private func fieldContainer<Content: View>(isError: Bool, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignTokens.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isError ? DesignTokens.dangerForeground : DesignTokens.border,
                                lineWidth: isError ? 1.5 : 1
                            )
                    )
            )
    }

    private func errorRow(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
                .font(.custom("Geist", size: 13, relativeTo: .body))
        }
        .foregroundStyle(DesignTokens.dangerForeground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(DesignTokens.dangerBackground))
    }

    private func submit() {
        let result = ManualEntryValidation.validate(url: serverURLText, username: username, password: password)
        urlError = result.urlError
        credError = result.credError
        guard result.urlError == nil, result.credError == nil, let url = URL(string: serverURLText) else { return }
        onSubmit(url, username, password)
    }

    private func applyConnectingFailure(_ error: PorquiloAPIError) {
        switch error {
        case .networkError, .noServerConfigured:
            credError = "Can't reach your server. Check the address and try again."
        case .serverError(let code, let message):
            credError = code == "invalid_credentials" ? "Wrong username or password." : message
        default:
            credError = "Something went wrong. Please try again."
        }
    }
}
