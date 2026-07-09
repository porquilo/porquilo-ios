import Foundation

enum EditLogEntryValidation {
    static func validate(quantityText: String) -> String? {
        guard let q = Double(quantityText), q > 0 else {
            return "Quantity must be greater than 0"
        }
        return nil
    }

    /// Mirrors the create-time rule (a manually-typed weight during a disconnected
    /// scale session commits as `quick_search`, not `scale`) applied to edits of
    /// already-committed entries: only demote a `scale` entry, and only when the
    /// quantity actually changed. Editing the time alone, or editing the quantity on
    /// an already-Estimated entry, must never touch `weight_source`.
    static func weightSourceToSend(originalWeightSource: String, quantityChanged: Bool) -> String? {
        (originalWeightSource == "scale" && quantityChanged) ? "quick_search" : nil
    }
}
