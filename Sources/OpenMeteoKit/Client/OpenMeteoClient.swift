import Foundation

/// A client for the free [Open-Meteo](https://open-meteo.com) weather APIs.
///
/// Every endpoint is an `async throws` method returning typed models. Open-Meteo needs no API key for
/// non-commercial use.
///
/// ```swift
/// let weather = OpenMeteoClient()
/// let places = try await weather.searchLocations("Istanbul")
/// let forecast = try await weather.forecast(ForecastRequest(coordinate: places[0].coordinate))
/// print(forecast.current?.temperature ?? 0, forecast.current?.weatherCode?.description ?? "")
/// ```
///
/// One client can be shared by the whole app; it is `Sendable` and keeps no per-request state.
/// Data from Open-Meteo is licensed under CC BY 4.0: credit Open-Meteo.com where you show it.
public final class OpenMeteoClient: Sendable {
    /// A client with the default configuration.
    public static let shared = OpenMeteoClient()

    public let configuration: OpenMeteoConfiguration

    public init(configuration: OpenMeteoConfiguration = OpenMeteoConfiguration()) {
        self.configuration = configuration
    }

    /// A client using `session`, with the default settings otherwise.
    public convenience init(session: URLSession) {
        self.init(configuration: OpenMeteoConfiguration(session: session))
    }

    // MARK: - Forecast

    /// A forecast with current conditions, hourly and daily data (`/v1/forecast`).
    public func forecast(_ request: ForecastRequest) async throws -> Forecast {
        try request.validate()
        return try await get(configuration.endpoints.forecast, query: request.queryItems)
    }

    /// A forecast for a coordinate. The defaults ask for what a weather app shows; pass empty arrays to leave a
    /// block out.
    public func forecast(
        latitude: Double,
        longitude: Double,
        current: [CurrentVariable] = ForecastRequest.defaultCurrent,
        hourly: [HourlyVariable] = ForecastRequest.defaultHourly,
        daily: [DailyVariable] = ForecastRequest.defaultDaily,
        units: WeatherUnits = .metric,
        timeZone: ForecastTimeZone = .auto,
        forecastDays: Int? = nil,
        pastDays: Int? = nil
    ) async throws -> Forecast {
        try await forecast(ForecastRequest(
            latitude: latitude,
            longitude: longitude,
            current: current,
            hourly: hourly,
            daily: daily,
            units: units,
            timeZone: timeZone,
            forecastDays: forecastDays,
            pastDays: pastDays
        ))
    }

    // MARK: - Historical weather

    /// Past weather from reanalysis data, back to 1940 (`/v1/archive`). The response has the same shape as a
    /// forecast, without current conditions.
    public func historical(_ request: HistoricalRequest) async throws -> Forecast {
        try request.validate()
        return try await get(configuration.endpoints.archive, query: request.queryItems)
    }

    /// Past daily weather for a coordinate between two days, both included.
    public func historical(
        latitude: Double,
        longitude: Double,
        from startDate: CalendarDate,
        to endDate: CalendarDate,
        hourly: [HourlyVariable] = [],
        daily: [DailyVariable] = [.weatherCode, .temperature2mMax, .temperature2mMin, .precipitationSum],
        units: WeatherUnits = .metric,
        timeZone: ForecastTimeZone = .auto
    ) async throws -> Forecast {
        try await historical(HistoricalRequest(
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            startDate: startDate,
            endDate: endDate,
            hourly: hourly,
            daily: daily,
            units: units,
            timeZone: timeZone
        ))
    }

    // MARK: - Air quality

    /// Air quality: particulate matter, gases and the European and US indexes (`/v1/air-quality`).
    public func airQuality(_ request: AirQualityRequest) async throws -> AirQuality {
        try request.validate()
        return try await get(configuration.endpoints.airQuality, query: request.queryItems)
    }

    /// Current and hourly air quality for a coordinate.
    public func airQuality(
        latitude: Double,
        longitude: Double,
        current: [AirQualityVariable] = AirQualityRequest.defaultVariables,
        hourly: [AirQualityVariable] = AirQualityRequest.defaultVariables,
        timeZone: ForecastTimeZone = .auto,
        forecastDays: Int? = nil
    ) async throws -> AirQuality {
        try await airQuality(AirQualityRequest(
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            current: current,
            hourly: hourly,
            timeZone: timeZone,
            forecastDays: forecastDays
        ))
    }

    // MARK: - Geocoding

    /// Places whose name matches `name`, the most populated first (`/v1/search`).
    ///
    /// Open-Meteo matches 2 characters exactly and 3 or more fuzzily; for fewer than 2 characters this returns
    /// an empty array without a request. A postal code works as well.
    ///
    /// - Parameters:
    ///   - count: The number of results, 1 to 100.
    ///   - language: The language of names and countries, as a lowercase ISO 639-1 code such as `"en"` or `"tr"`.
    ///   - countryCode: Only places in this ISO 3166-1 alpha-2 country, such as `"TR"`.
    public func searchLocations(
        _ name: String,
        count: Int = 10,
        language: String = "en",
        countryCode: String? = nil
    ) async throws -> [Location] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        guard (1...100).contains(count) else {
            throw OpenMeteoError.invalidRequest("count must be between 1 and 100, not \(count).")
        }
        var query = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "format", value: "json"),
        ]
        if let countryCode {
            query.append(URLQueryItem(name: "countryCode", value: countryCode))
        }
        let response: GeocodingResponse = try await get(
            configuration.endpoints.geocoding.appendingPathComponent("search"),
            query: query
        )
        return response.results ?? []
    }

    /// A place by its GeoNames id (`/v1/get`).
    public func location(id: Int, language: String = "en") async throws -> Location {
        try await get(configuration.endpoints.geocoding.appendingPathComponent("get"), query: [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "language", value: language),
        ])
    }

    // MARK: - Requests

    /// Builds the request for an endpoint and its parameters. Exposed for tests and debugging.
    public func request(_ url: URL, query: [URLQueryItem]) throws -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw OpenMeteoError.transport(URLError(.badURL))
        }
        var items = query
        if let apiKey = configuration.apiKey {
            items.append(URLQueryItem(name: "apikey", value: apiKey))
        }
        if !items.isEmpty {
            components.queryItems = items
            // URLComponents leaves "+" as is, but servers read it as a space.
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
        }
        guard let finalURL = components.url else {
            throw OpenMeteoError.transport(URLError(.badURL))
        }
        var request = URLRequest(url: finalURL, timeoutInterval: configuration.timeout)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let userAgent = configuration.userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        return request
    }

    /// Fetches and decodes any Open-Meteo endpoint, for APIs this client has no method for (marine, flood,
    /// ensemble…), into your own `Decodable` or into ``Forecast``, whose shape most of them share.
    public func get<T: Decodable>(_ url: URL, query: [URLQueryItem], as type: T.Type = T.self) async throws -> T {
        let urlRequest = try request(url, query: query)
        let result: (Data, URLResponse)
        do {
            result = try await configuration.session.data(for: urlRequest)
        } catch let error as URLError {
            throw OpenMeteoError.transport(error)
        }
        let (data, response) = result
        guard let http = response as? HTTPURLResponse else {
            throw OpenMeteoError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            if let body = try? JSONDecoder().decode(APIErrorBody.self, from: data), body.error {
                throw OpenMeteoError.api(reason: body.reason, statusCode: http.statusCode)
            }
            throw OpenMeteoError.http(statusCode: http.statusCode, url: urlRequest.url ?? url)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // Open-Meteo can also report an error with a 200 status.
            if let body = try? JSONDecoder().decode(APIErrorBody.self, from: data), body.error {
                throw OpenMeteoError.api(reason: body.reason, statusCode: http.statusCode)
            }
            throw OpenMeteoError.decoding(type: String(describing: T.self), description: String(describing: error))
        }
    }
}
