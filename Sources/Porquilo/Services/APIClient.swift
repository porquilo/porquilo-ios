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

extension PorquiloAPIError: Equatable {
    static func == (lhs: PorquiloAPIError, rhs: PorquiloAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.serverError(let lCode, let lMessage), .serverError(let rCode, let rMessage)):
            return lCode == rCode && lMessage == rMessage
        case (.networkError, .networkError),
             (.decodingError, .decodingError),
             (.noServerConfigured, .noServerConfigured),
             (.unauthorized, .unauthorized):
            return true
        default:
            return false
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

    private struct LoginRequestBody: Encodable {
        let username: String
        let password: String
    }

    private struct PairingExchangeBody: Encodable {
        let code: String
    }

    private struct LoginResponse: Decodable {
        let token: String
        let user: User
    }

    private struct VersionResponse: Decodable {
        let version: String
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
        let request = Self.buildRequest(
            url: baseURL.appendingPathComponent(path),
            method: method,
            body: body,
            authToken: KeychainService.load()
        )
        return try await Self.perform(request)
    }

    /// Builds its request from the passed-in `serverURL`, not the stored `baseURL` —
    /// at call time the server hasn't been configured yet (the user is mid-login).
    func login(serverURL: URL, username: String, password: String) async throws -> (token: String, user: User) {
        let request = Self.buildRequest(
            url: serverURL.appendingPathComponent("api/auth/token"),
            method: "POST",
            body: LoginRequestBody(username: username, password: password),
            authToken: nil
        )
        let response: LoginResponse = try await Self.perform(request)
        return (response.token, response.user)
    }

    /// Builds its request from the scanned `serverURL`, not the stored `baseURL`.
    func exchangePairingCode(_ code: String, serverURL: URL) async throws -> (token: String, user: User) {
        let request = Self.buildRequest(
            url: serverURL.appendingPathComponent("api/auth/pairing/exchange"),
            method: "POST",
            body: PairingExchangeBody(code: code),
            authToken: nil
        )
        let response: LoginResponse = try await Self.perform(request)
        return (response.token, response.user)
    }

    func fetchServerVersion() async throws -> String {
        guard let baseURL else { throw PorquiloAPIError.noServerConfigured }
        let request = Self.buildRequest(
            url: baseURL.appendingPathComponent("api/version"),
            method: "GET",
            body: nil,
            authToken: nil
        )
        let response: VersionResponse = try await Self.perform(request)
        return response.version
    }

    private static func buildRequest(
        url: URL,
        method: String,
        body: (any Encodable)?,
        authToken: String?
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(AnyEncodable(body))
        }

        return request
    }

    private static func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
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
            throw serverError(from: data)
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
