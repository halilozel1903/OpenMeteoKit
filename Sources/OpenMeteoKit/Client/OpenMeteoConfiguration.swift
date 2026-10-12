import Foundation

/// The addresses of Open-Meteo's APIs. Each one has its own host.
public struct OpenMeteoEndpoints: Hashable, Sendable {
    /// `https://api.open-meteo.com/v1/forecast`.
    public var forecast: URL
    /// `https://archive-api.open-meteo.com/v1/archive`.
    public var archive: URL
    /// `https://air-quality-api.open-meteo.com/v1/air-quality`.
    public var airQuality: URL
    /// `https://geocoding-api.open-meteo.com/v1`; `search` and `get` are appended.
    public var geocoding: URL

    public init(forecast: URL, archive: URL, airQuality: URL, geocoding: URL) {
        self.forecast = forecast
        self.archive = archive
        self.airQuality = airQuality
        self.geocoding = geocoding
    }

    /// The free, non-commercial APIs.
    public static let free = OpenMeteoEndpoints(
        forecast: URL(string: "https://api.open-meteo.com/v1/forecast")!,
        archive: URL(string: "https://archive-api.open-meteo.com/v1/archive")!,
        airQuality: URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!,
        geocoding: URL(string: "https://geocoding-api.open-meteo.com/v1")!
    )

    /// The commercial APIs, on `customer-` hosts. Use them with an API key.
    public static let customer = OpenMeteoEndpoints(
        forecast: URL(string: "https://customer-api.open-meteo.com/v1/forecast")!,
        archive: URL(string: "https://customer-archive-api.open-meteo.com/v1/archive")!,
        airQuality: URL(string: "https://customer-air-quality-api.open-meteo.com/v1/air-quality")!,
        geocoding: URL(string: "https://customer-geocoding-api.open-meteo.com/v1")!
    )

    /// Every API on one base URL with Open-Meteo's paths (`/v1/forecast`, `/v1/archive`, `/v1/air-quality`,
    /// `/v1/search`, `/v1/get`), for a self-hosted Open-Meteo or a stub server.
    public static func host(_ baseURL: URL) -> OpenMeteoEndpoints {
        let v1 = baseURL.appendingPathComponent("v1")
        return OpenMeteoEndpoints(
            forecast: v1.appendingPathComponent("forecast"),
            archive: v1.appendingPathComponent("archive"),
            airQuality: v1.appendingPathComponent("air-quality"),
            geocoding: v1
        )
    }
}

/// Settings of an ``OpenMeteoClient``.
public struct OpenMeteoConfiguration: Sendable {
    /// Where requests go.
    public var endpoints: OpenMeteoEndpoints
    /// Sent as `apikey` with every request, for the commercial APIs.
    public var apiKey: String?
    /// The session that performs requests. Give it a `URLProtocol` subclass to stub responses.
    public var session: URLSession
    /// Sent as `User-Agent`.
    public var userAgent: String?
    /// The request timeout in seconds.
    public var timeout: TimeInterval

    public init(
        endpoints: OpenMeteoEndpoints = .free,
        apiKey: String? = nil,
        session: URLSession = .shared,
        userAgent: String? = "OpenMeteoKit (+https://github.com/halilozel1903/OpenMeteoKit)",
        timeout: TimeInterval = 20
    ) {
        self.endpoints = endpoints
        self.apiKey = apiKey
        self.session = session
        self.userAgent = userAgent
        self.timeout = timeout
    }

    /// The commercial APIs with your API key.
    public static func customer(apiKey: String, session: URLSession = .shared) -> OpenMeteoConfiguration {
        OpenMeteoConfiguration(endpoints: .customer, apiKey: apiKey, session: session)
    }
}
