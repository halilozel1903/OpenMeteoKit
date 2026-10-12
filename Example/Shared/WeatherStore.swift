import Foundation
import Observation
import OpenMeteoKit

/// The weather of one place: its forecast and its air quality, loaded together.
@MainActor
@Observable
final class WeatherStore {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var location: Location
    private(set) var forecast: Forecast?
    private(set) var airQuality: AirQuality?
    private(set) var phase: Phase = .idle

    let client: OpenMeteoClient
    /// How many times a load is tried before it fails. Screenshot scenes retry, so a brief network hiccup on a CI
    /// runner does not fail the job; there is no fallback data, so a scene that cannot load never signals ready.
    let attempts: Int

    init(client: OpenMeteoClient = .shared, location: Location = .istanbul, attempts: Int = 1) {
        self.client = client
        self.location = location
        self.attempts = max(1, attempts)
    }

    /// Always the live API. A screenshot scene tries harder, but shows only real data.
    static func make(for scene: ScreenshotScene?) -> WeatherStore {
        WeatherStore(attempts: scene == nil ? 1 : 4)
    }

    /// The current conditions, once the forecast has loaded.
    var current: CurrentWeather? {
        forecast?.current
    }

    /// Loads the forecast and the air quality of ``location``, trying up to ``attempts`` times with a growing pause.
    /// A failed air quality request leaves the forecast on screen.
    func load() async {
        phase = .loading
        var lastError: (any Error)?
        for attempt in 1...attempts {
            do {
                try await fetch()
                phase = .loaded
                return
            } catch {
                lastError = error
                guard attempt < attempts, !Task.isCancelled else { break }
                try? await Task.sleep(for: .seconds(Double(attempt * 3)))
            }
        }
        phase = .failed(lastError?.localizedDescription ?? "The forecast could not be loaded.")
    }

    private func fetch() async throws {
        let coordinate = location.coordinate
        let client = self.client
        async let forecastRequest = client.forecast(ForecastRequest(coordinate: coordinate, forecastDays: 7))
        async let airQualityRequest = client.airQuality(AirQualityRequest(coordinate: coordinate, forecastDays: 2))
        let loadedForecast = try await forecastRequest
        let loadedAirQuality = try? await airQualityRequest
        forecast = loadedForecast
        airQuality = loadedAirQuality
    }

    /// Shows another place.
    func select(_ location: Location) async {
        self.location = location
        forecast = nil
        airQuality = nil
        await load()
    }
}

extension Location {
    /// Where the app starts.
    static let istanbul = Location(
        id: 745044,
        name: "Istanbul",
        latitude: 41.01384,
        longitude: 28.94966,
        elevation: 39,
        featureCode: "PPLA",
        countryCode: "TR",
        country: "Türkiye",
        timezone: "Europe/Istanbul",
        population: 14_804_116,
        admin1: "Istanbul"
    )
}
