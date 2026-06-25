import Foundation

struct QRPairingPayload: Decodable {
    let server: String
    let code: String
}

enum QRPairingPayloadParser {
    /// Parses a raw scanned QR string into a validated server URL + pairing code.
    /// Returns `nil` if the payload isn't valid JSON, doesn't match the expected
    /// shape, or the server field isn't an http(s) URL.
    static func parse(_ raw: String) -> (serverURL: URL, code: String)? {
        guard let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(QRPairingPayload.self, from: data) else {
            return nil
        }
        guard payload.server.hasPrefix("http://") || payload.server.hasPrefix("https://"),
              let url = URL(string: payload.server) else {
            return nil
        }
        return (url, payload.code)
    }
}
