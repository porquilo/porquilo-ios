import AVFoundation
import SwiftUI

struct QRScannerView: View {
    let onCancel: () -> Void
    let onScanSuccess: (URL, String) -> Void
    @Binding var connectingError: PorquiloAPIError?

    /// Hardcoded — this screen simulates a camera viewfinder and must stay dark
    /// regardless of system color scheme, unlike every other themeable screen in the app.
    private static let viewfinderBackground = Color(red: 10 / 255, green: 8 / 255, blue: 6 / 255)
    private static let viewfinderWell = Color(red: 8 / 255, green: 6 / 255, blue: 4 / 255)
    private static let mutedWarmWhite = Color.white.opacity(0.36)

    private enum CameraPermissionState {
        case notDetermined
        case authorized
        case denied
    }

    @State private var coordinator = QRCaptureCoordinator()
    @State private var permissionState: CameraPermissionState = .notDetermined
    @State private var scanError: String?
    @State private var scanLineAtBottom = false

    var body: some View {
        ZStack {
            Self.viewfinderBackground.ignoresSafeArea()

            if permissionState == .authorized {
                CameraPreviewView(session: coordinator.session)
                    .ignoresSafeArea()
            }

            VStack {
                Text("POINT YOUR CAMERA AT THE QR CODE")
                    .font(.porqCaption)
                    .foregroundStyle(Self.mutedWarmWhite)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                Spacer()

                if permissionState == .denied {
                    permissionDeniedMessage
                } else {
                    viewfinder

                    Text(scanError ?? "Waiting for code…")
                        .font(.custom("Geist", size: 14, relativeTo: .body))
                        .foregroundStyle(Self.mutedWarmWhite)
                        .padding(.top, 16)
                }

                Spacer()

                Button(action: {
                    coordinator.stopSession()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.custom("Geist", size: 15, relativeTo: .body))
                        .foregroundStyle(Self.mutedWarmWhite)
                }
                .padding(.bottom, 18)
            }
        }
        .task {
            await requestPermissionIfNeeded()
        }
        .onAppear {
            coordinator.onCodeScanned = { raw in
                guard let parsed = QRPairingPayloadParser.parse(raw) else {
                    scanError = "Couldn't read that code"
                    return
                }
                scanError = nil
                coordinator.stopSession()
                onScanSuccess(parsed.serverURL, parsed.code)
            }
            scanLineAtBottom = true
        }
        .onDisappear {
            coordinator.stopSession()
        }
        .onChange(of: connectingError) { _, newValue in
            guard newValue != nil else { return }
            scanError = "Couldn't read that code"
            connectingError = nil
            coordinator.startSession()
        }
    }

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Self.viewfinderWell)
                .frame(width: 260, height: 260)

            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, DesignTokens.accent, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 260, height: 2)
                    .opacity(0.9)
                    .offset(y: scanLineAtBottom ? 260 * 0.88 - 130 : 260 * 0.05 - 130)
                    .animation(
                        .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                        value: scanLineAtBottom
                    )
            }
            .frame(width: 260, height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            cornerBrackets
        }
        .frame(width: 260, height: 260)
    }

    private var cornerBrackets: some View {
        let length: CGFloat = 30
        let thickness: CGFloat = 4
        let inset: CGFloat = 130 - 4

        return ZStack {
            bracket(length: length, thickness: thickness)
                .position(x: -inset + length / 2, y: -inset + thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: -inset + thickness / 2, y: -inset + length / 2)

            bracket(length: length, thickness: thickness)
                .position(x: inset - length / 2, y: -inset + thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: inset - thickness / 2, y: -inset + length / 2)

            bracket(length: length, thickness: thickness)
                .position(x: -inset + length / 2, y: inset - thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: -inset + thickness / 2, y: inset - length / 2)

            bracket(length: length, thickness: thickness)
                .position(x: inset - length / 2, y: inset - thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: inset - thickness / 2, y: inset - length / 2)
        }
    }

    private func bracket(length: CGFloat, thickness: CGFloat) -> some View {
        Rectangle()
            .fill(DesignTokens.accent)
            .frame(width: length, height: thickness)
    }

    private var permissionDeniedMessage: some View {
        VStack(spacing: 16) {
            Text("Camera access is needed to scan pairing codes.")
                .font(.custom("Geist", size: 14, relativeTo: .body))
                .foregroundStyle(Self.mutedWarmWhite)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }) {
                Text("Open Settings")
                    .font(.custom("Geist", size: 15, relativeTo: .body))
                    .foregroundStyle(DesignTokens.accent)
            }
        }
    }

    private func requestPermissionIfNeeded() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionState = .authorized
            coordinator.startSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionState = granted ? .authorized : .denied
            if granted { coordinator.startSession() }
        default:
            permissionState = .denied
        }
    }
}
