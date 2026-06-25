import SwiftUI

enum QuickLogStep: Equatable {
    case search
    case barcodeScanner
    case barcodeNotFound(barcode: String)
    // .quantity is added in iOS-6
}

struct QuickLogView: View {
    let onDismiss: () -> Void

    @State private var step: QuickLogStep = .search
    @State private var candidate: LogCandidate? = nil
    @State private var isOffline: Bool = false

    var body: some View {
        switch step {
        case .search:
            QuickLogSearchView(step: $step, candidate: $candidate, isOffline: $isOffline, onDismiss: onDismiss)
        case .barcodeScanner:
            BarcodeScanView(step: $step, candidate: $candidate, isOffline: $isOffline, onDismiss: onDismiss)
        case .barcodeNotFound(let barcode):
            BarcodeNotFoundView(barcode: barcode, step: $step, onDismiss: onDismiss)
        }
    }
}
