import SwiftUI

enum QuickLogStep: Equatable {
    case search
    case barcodeScanner
    case barcodeNotFound(barcode: String)
    case quantity(LogCandidate)
}

struct QuickLogView: View {
    let onDismiss: () -> Void
    let onLogged: () -> Void

    @State private var step: QuickLogStep = .search
    @State private var candidate: LogCandidate? = nil
    @State private var isOffline: Bool = false
    @State private var meals: [Meal] = []

    var body: some View {
        Group {
            switch step {
            case .search:
                QuickLogSearchView(step: $step, candidate: $candidate, isOffline: $isOffline, onDismiss: onDismiss)
            case .barcodeScanner:
                BarcodeScanView(step: $step, candidate: $candidate, isOffline: $isOffline, onDismiss: onDismiss)
            case .barcodeNotFound(let barcode):
                BarcodeNotFoundView(barcode: barcode, step: $step, onDismiss: onDismiss)
            case .quantity(let candidate):
                QuantityView(candidate: candidate, meals: meals, step: $step, onLogged: {
                    onDismiss()
                    onLogged()
                })
            }
        }
        .task {
            meals = (try? await APIClient.shared.fetchMeals()) ?? []
        }
    }
}
