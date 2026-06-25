import AVFoundation
import SwiftUI

struct BarcodeScanView: View {
    @Binding var step: QuickLogStep
    @Binding var candidate: LogCandidate?
    @Binding var isOffline: Bool
    let onDismiss: () -> Void
    @Environment(AppState.self) private var appState

    /// Hardcoded — this screen simulates a camera viewfinder and must stay dark
    /// regardless of system color scheme, same rationale as QRScannerView in iOS-2.
    private static let viewfinderBackground = Color(red: 13 / 255, green: 11 / 255, blue: 9 / 255)

    @State private var coordinator = BarcodeCaptureCoordinator()
    @State private var torchOn = false
    @State private var scanLineAtBottom = false

    var body: some View {
        ZStack {
            Self.viewfinderBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topControls

                ZStack {
                    RadialGradient(
                        colors: [Color(red: 0x22 / 255, green: 0x1C / 255, blue: 0x14 / 255), Color(red: 9 / 255, green: 7 / 255, blue: 5 / 255)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 320
                    )

                    CameraPreviewView(session: coordinator.session)
                        .opacity(0.85)

                    scanFrame

                    VStack {
                        Spacer()
                        hintArea
                    }
                }
            }
        }
        .task {
            await requestPermissionIfNeeded()
        }
        .onAppear {
            coordinator.onBarcodeScanned = { barcode in
                handleScan(barcode)
            }
            scanLineAtBottom = true
        }
        .onDisappear {
            coordinator.stopSession()
        }
    }

    private var topControls: some View {
        ZStack {
            Text("Scan barcode")
                .font(.custom("Newsreader", size: 17))
                .foregroundStyle(.white)

            HStack {
                Button(action: {
                    coordinator.stopSession()
                    onDismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(0.11))
                        .clipShape(Capsule())
                }

                Spacer()

                Button(action: toggleTorch) {
                    Image(systemName: torchOn ? "bolt.fill" : "bolt")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .padding(.top, 16)
    }

    private var scanFrame: some View {
        GeometryReader { proxy in
            ZStack {
                cornerBrackets

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color(red: 224 / 255, green: 117 / 255, blue: 83 / 255).opacity(0.18),
                                Color(red: 245 / 255, green: 149 / 255, blue: 106 / 255),
                                Color(red: 224 / 255, green: 117 / 255, blue: 83 / 255).opacity(0.18),
                                .clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 282 - 20, height: 2)
                    .shadow(color: Color(red: 224 / 255, green: 117 / 255, blue: 83 / 255).opacity(0.7), radius: 4)
                    .offset(y: scanLineAtBottom ? 158 * 0.85 - 79 : 158 * 0.08 - 79)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: scanLineAtBottom)
            }
            .frame(width: 282, height: 158)
            .position(x: proxy.size.width / 2, y: proxy.size.height * 0.57)
        }
    }

    private var cornerBrackets: some View {
        let length: CGFloat = 26
        let thickness: CGFloat = 2.5
        let insetX: CGFloat = 282 / 2
        let insetY: CGFloat = 158 / 2

        return ZStack {
            bracket(length: length, thickness: thickness)
                .position(x: -insetX + length / 2, y: -insetY + thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: -insetX + thickness / 2, y: -insetY + length / 2)

            bracket(length: length, thickness: thickness)
                .position(x: insetX - length / 2, y: -insetY + thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: insetX - thickness / 2, y: -insetY + length / 2)

            bracket(length: length, thickness: thickness)
                .position(x: -insetX + length / 2, y: insetY - thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: -insetX + thickness / 2, y: insetY - length / 2)

            bracket(length: length, thickness: thickness)
                .position(x: insetX - length / 2, y: insetY - thickness / 2)
            bracket(length: thickness, thickness: length)
                .position(x: insetX - thickness / 2, y: insetY - length / 2)
        }
    }

    private func bracket(length: CGFloat, thickness: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.85))
            .frame(width: length, height: thickness)
    }

    private var hintArea: some View {
        VStack(spacing: 8) {
            Text("Align barcode in frame")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))

            Button(action: { step = .search }) {
                Text("Search instead")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .underline()
            }
        }
        .frame(height: 52)
        .padding(.bottom, 24)
    }

    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = torchOn ? .off : .on
            torchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            // Torch is a convenience control — if it can't be configured, silently no-op.
        }
    }

    private func handleScan(_ barcode: String) {
        coordinator.stopSession()
        Task {
            do {
                let result = try await APIClient.shared.lookupBarcode(barcode)
                let selected = LogCandidate(result: result, origin: .barcode)
                candidate = selected
                step = .quantity(selected)
            } catch PorquiloAPIError.notFound {
                step = .barcodeNotFound(barcode: barcode)
            } catch PorquiloAPIError.unauthorized {
                appState.signOut()
            } catch PorquiloAPIError.networkError(_), PorquiloAPIError.noServerConfigured {
                isOffline = true
                step = .search
            } catch {
                step = .search
            }
        }
    }

    private func requestPermissionIfNeeded() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            coordinator.startSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { coordinator.startSession() }
        default:
            break
        }
    }
}

/// Bridges `AVCaptureSession`'s EAN/UPC metadata callbacks into a plain closure,
/// mirroring `QRCaptureCoordinator`'s role for the pairing scanner in iOS-2.
final class BarcodeCaptureCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var onBarcodeScanned: ((String) -> Void)?

    private var isConfigured = false

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce]
    }

    func startSession() {
        configureIfNeeded()
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              [.ean13, .ean8, .upce].contains(object.type),
              let value = object.stringValue else { return }
        onBarcodeScanned?(value)
    }
}
