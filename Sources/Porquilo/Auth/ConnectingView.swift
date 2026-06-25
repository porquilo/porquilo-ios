import SwiftUI

struct ConnectingView: View {
    let serverURL: URL
    let operation: () async throws -> (token: String, user: User)
    let onSuccess: (String, String) -> Void
    let onFailure: (PorquiloAPIError) -> Void

    private enum Phase {
        case connecting
        case verifying
        case connected
    }

    @State private var phase: Phase = .connecting

    private var host: String {
        var string = serverURL.absoluteString
        for scheme in ["https://", "http://"] where string.hasPrefix(scheme) {
            string.removeFirst(scheme.count)
        }
        return string.split(separator: "/").first.map(String.init) ?? string
    }

    private var statusText: String {
        switch phase {
        case .connecting: return "Connecting to \(host)…"
        case .verifying: return "Verifying credentials…"
        case .connected: return "Connected."
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            indicator

            Text(statusText)
                .font(.porqBody)
                .foregroundStyle(DesignTokens.textTertiary)
                .multilineTextAlignment(.center)

            if phase != .connected {
                Text(host)
                    .font(.custom("Geist Mono", size: 13, relativeTo: .body))
                    .foregroundStyle(DesignTokens.accent)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background)
        .task {
            await runSequence()
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch phase {
        case .connecting, .verifying:
            SpinnerView()
        case .connected:
            ZStack {
                Circle().fill(DesignTokens.successBackground).frame(width: 52, height: 52)
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DesignTokens.successForeground)
            }
            .transition(.opacity.combined(with: .offset(y: -10)))
        }
    }

    private func runSequence() async {
        async let outcome: Result<(token: String, user: User), PorquiloAPIError> = {
            do {
                let result = try await operation()
                return .success(result)
            } catch let error as PorquiloAPIError {
                return .failure(error)
            } catch {
                return .failure(.networkError(error))
            }
        }()

        try? await Task.sleep(for: .seconds(0.8))
        phase = .verifying

        // Phase 1→2 is gated on the real network result, with the spec's 1.8s mark
        // treated as a minimum hold so the UI never claims success before the
        // server has actually responded.
        async let floor = Task.sleep(for: .seconds(1.0))
        let result = await outcome
        _ = try? await floor

        switch result {
        case .success(let value):
            withAnimation(.easeOut(duration: 0.3)) {
                phase = .connected
            }
            try? await Task.sleep(for: .seconds(1.0))
            onSuccess(value.token, serverURL.absoluteString)
        case .failure(let error):
            onFailure(error)
        }
    }
}

private struct SpinnerView: View {
    @State private var isRotating = false

    var body: some View {
        Circle()
            .stroke(DesignTokens.border, lineWidth: 3)
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(DesignTokens.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
            )
            .onAppear {
                withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }
    }
}
