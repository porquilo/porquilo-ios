import Foundation

enum PorquiloAPIError: Error, LocalizedError {
    case serverError(code: String, message: String)
    case networkError(Error)
    case decodingError(Error)
    case noServerConfigured
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .serverError(_, let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return error.localizedDescription
        case .noServerConfigured:
            return "No server configured."
        case .unauthorized:
            return "Unauthorized."
        }
    }
}

@Observable
final class APIClient {
    static let shared = APIClient()

    private var baseURL: URL? {
        guard let raw = UserDefaults.standard.string(forKey: AppConstants.serverURLKey),
              let url = URL(string: raw) else { return nil }
        return url
    }

    private struct ErrorEnvelope: Decodable {
        struct Inner: Decodable {
            let code: String
            let message: String
        }
        let error: Inner
    }

    static func serverError(from data: Data) -> PorquiloAPIError {
        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
            return .serverError(code: envelope.error.code, message: envelope.error.message)
        }
        return .networkError(URLError(.badServerResponse))
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let baseURL else { throw PorquiloAPIError.noServerConfigured }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method

        if let token = KeychainService.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(AnyEncodable(body))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PorquiloAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PorquiloAPIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw PorquiloAPIError.unauthorized
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            throw Self.serverError(from: data)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw PorquiloAPIError.decodingError(error)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ encodable: any Encodable) {
        self.encodeClosure = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
