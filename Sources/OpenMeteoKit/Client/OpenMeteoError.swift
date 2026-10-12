import Foundation

/// Errors thrown by ``OpenMeteoClient``.
public enum OpenMeteoError: Error, Equatable, Sendable, LocalizedError {
    /// Open-Meteo rejected the request and said why, as in
    /// `{"error": true, "reason": "Cannot initialize WeatherVariable from invalid String value…"}`.
    case api(reason: String, statusCode: Int)
    /// The request was not sent because a parameter is out of range (checked before any network access).
    case invalidRequest(String)
    /// An unsuccessful HTTP status without Open-Meteo's error body.
    case http(statusCode: Int, url: URL)
    /// The response was not JSON of the expected shape.
    case decoding(type: String, description: String)
    /// The request could not be completed (offline, timed out, cancelled…).
    case transport(URLError)
    /// The response was not an HTTP response.
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case let .api(reason, _):
            return reason
        case let .invalidRequest(reason):
            return reason
        case let .http(statusCode, _):
            return "Open-Meteo answered with HTTP status \(statusCode)."
        case let .decoding(type, _):
            return "Open-Meteo sent data that could not be read as \(type)."
        case let .transport(error):
            return error.localizedDescription
        case .invalidResponse:
            return "Open-Meteo sent an invalid response."
        }
    }
}

/// The body Open-Meteo sends with a 400 Bad Request.
struct APIErrorBody: Decodable {
    let error: Bool
    let reason: String
}
