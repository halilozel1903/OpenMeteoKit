import Foundation
import Testing
@testable import OpenMeteoKit

@Suite("OpenMeteoClient requests")
struct ClientTests {
    // MARK: - Forecast

    @Test func forecastWithTheDefaults() async throws {
        let stub = StubbedClient { _ in try .json("forecast-istanbul") }
        let forecast = try await stub.client.forecast(latitude: 41.01, longitude: 28.95)

        #expect(forecast.current?.temperature == 21.9)
        #expect(stub.lastPath == "/v1/forecast")
        #expect(stub.lastQueryValue("latitude") == "41.01")
        #expect(stub.lastQueryValue("longitude") == "28.95")
        #expect(stub.lastQueryValue("current") == ForecastRequest.defaultCurrent.queryValue)
        #expect(stub.lastQueryValue("hourly") == ForecastRequest.defaultHourly.queryValue)
        #expect(stub.lastQueryValue("daily") == ForecastRequest.defaultDaily.queryValue)
        #expect(stub.lastQueryValue("timezone") == "auto")
        // Metric is the API's default, so no unit parameters are sent.
        #expect(stub.lastQueryValue("temperature_unit") == nil)
        #expect(stub.lastQueryValue("wind_speed_unit") == nil)
        #expect(stub.lastQueryValue("precipitation_unit") == nil)
        #expect(stub.lastQueryValue("forecast_days") == nil)
    }

    @Test func forecastVariablesUnitsAndDays() async throws {
        let stub = StubbedClient { _ in try .json("forecast-istanbul") }
        var request = ForecastRequest(
            latitude: 41.01,
            longitude: 28.95,
            current: [.temperature2m, .weatherCode, .temperature2m],
            hourly: [.temperature2m, .precipitationProbability],
            daily: [],
            units: .imperial,
            timeZone: .identifier("Europe/Istanbul"),
            forecastDays: 3,
            pastDays: 1
        )
        request.forecastHours = 24
        request.models = ["ecmwf_ifs025", "icon_seamless"]
        _ = try await stub.client.forecast(request)

        #expect(stub.lastQueryValue("current") == "temperature_2m,weather_code")
        #expect(stub.lastQueryValue("hourly") == "temperature_2m,precipitation_probability")
        #expect(stub.lastQueryValue("daily") == nil)
        #expect(stub.lastQueryValue("temperature_unit") == "fahrenheit")
        #expect(stub.lastQueryValue("wind_speed_unit") == "mph")
        #expect(stub.lastQueryValue("precipitation_unit") == "inch")
        #expect(stub.lastQueryValue("timezone") == "Europe/Istanbul")
        #expect(stub.lastQueryValue("forecast_days") == "3")
        #expect(stub.lastQueryValue("past_days") == "1")
        #expect(stub.lastQueryValue("forecast_hours") == "24")
        #expect(stub.lastQueryValue("models") == "ecmwf_ifs025,icon_seamless")
    }

    @Test func gmtAndFoundationTimeZones() {
        #expect(ForecastTimeZone.gmt.queryValue == "GMT")
        #expect(ForecastTimeZone(TimeZone(identifier: "America/New_York")!).queryValue == "America/New_York")
    }

    @Test func invalidRequestsAreNotSent() async throws {
        let stub = StubbedClient { _ in try .json("forecast-istanbul") }

        let tooManyDays = await #expect(throws: OpenMeteoError.self) {
            try await stub.client.forecast(ForecastRequest(latitude: 41, longitude: 29, forecastDays: 17))
        }
        #expect(tooManyDays == .invalidRequest("forecast_days must be between 0 and 16, not 17."))

        await #expect(throws: OpenMeteoError.self) {
            try await stub.client.forecast(latitude: 91, longitude: 0)
        }
        await #expect(throws: OpenMeteoError.self) {
            try await stub.client.forecast(latitude: .nan, longitude: 0)
        }
        await #expect(throws: OpenMeteoError.self) {
            try await stub.client.forecast(ForecastRequest(latitude: 41, longitude: 29, pastDays: 93))
        }
        #expect(stub.requests.isEmpty)
    }

    @Test func headers() async throws {
        let stub = StubbedClient { _ in try .json("forecast-istanbul") }
        _ = try await stub.client.forecast(latitude: 41.01, longitude: 28.95)

        let request = try #require(stub.requests.last)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        let agent = request.value(forHTTPHeaderField: "User-Agent") ?? ""
        #expect(agent.hasPrefix("OpenMeteoKit"))
    }

    @Test func apiKeyIsSentForCommercialUse() async throws {
        let stub = StubbedClient(apiKey: "secret-key") { _ in try .json("forecast-istanbul") }
        _ = try await stub.client.forecast(latitude: 41.01, longitude: 28.95)

        #expect(stub.lastQueryValue("apikey") == "secret-key")
    }

    // MARK: - Historical

    @Test func historical() async throws {
        let stub = StubbedClient { _ in try .json("archive-istanbul") }
        let archive = try await stub.client.historical(
            latitude: 41.01,
            longitude: 28.95,
            from: CalendarDate(year: 2026, month: 9, day: 1),
            to: CalendarDate(year: 2026, month: 9, day: 7),
            daily: [.weatherCode, .temperature2mMax, .temperature2mMin, .precipitationSum, .sunrise, .sunset]
        )

        #expect(archive.dailyWeather.count == 7)
        #expect(stub.lastPath == "/v1/archive")
        #expect(stub.lastQueryValue("start_date") == "2026-09-01")
        #expect(stub.lastQueryValue("end_date") == "2026-09-07")
        #expect(stub.lastQueryValue("daily") == "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,sunrise,sunset")
        #expect(stub.lastQueryValue("hourly") == nil)
        #expect(stub.lastQueryValue("timezone") == "auto")
    }

    @Test func historicalRangeMustBeInOrder() async throws {
        let stub = StubbedClient { _ in try .json("archive-istanbul") }

        await #expect(throws: OpenMeteoError.self) {
            try await stub.client.historical(
                latitude: 41.01,
                longitude: 28.95,
                from: CalendarDate(year: 2026, month: 9, day: 7),
                to: CalendarDate(year: 2026, month: 9, day: 1)
            )
        }
        await #expect(throws: OpenMeteoError.self) {
            try await stub.client.historical(HistoricalRequest(
                coordinate: Coordinate(latitude: 41, longitude: 29),
                startDate: CalendarDate(year: 2026, month: 9, day: 1),
                endDate: CalendarDate(year: 2026, month: 9, day: 1),
                daily: []
            ))
        }
        #expect(stub.requests.isEmpty)
    }

    // MARK: - Air quality

    @Test func airQuality() async throws {
        let stub = StubbedClient { _ in try .json("air-quality-istanbul") }
        let air = try await stub.client.airQuality(latitude: 41.01, longitude: 28.95)

        #expect(air.current?.europeanAQI == 27)
        #expect(stub.lastPath == "/v1/air-quality")
        #expect(stub.lastQueryValue("current") == "european_aqi,us_aqi,pm10,pm2_5")
        #expect(stub.lastQueryValue("hourly") == "european_aqi,us_aqi,pm10,pm2_5")
        #expect(stub.lastQueryValue("timezone") == "auto")
        #expect(stub.lastQueryValue("domains") == nil)
    }

    @Test func airQualityDomainAndDays() async throws {
        let stub = StubbedClient { _ in try .json("air-quality-istanbul") }
        _ = try await stub.client.airQuality(AirQualityRequest(
            coordinate: Coordinate(latitude: 41.01, longitude: 28.95),
            current: [.ozone],
            hourly: [],
            forecastDays: 2,
            domain: .camsEurope
        ))

        #expect(stub.lastQueryValue("current") == "ozone")
        #expect(stub.lastQueryValue("hourly") == nil)
        #expect(stub.lastQueryValue("forecast_days") == "2")
        #expect(stub.lastQueryValue("domains") == "cams_europe")

        await #expect(throws: OpenMeteoError.self) {
            try await stub.client.airQuality(AirQualityRequest(
                coordinate: Coordinate(latitude: 41.01, longitude: 28.95),
                forecastDays: 8
            ))
        }
    }

    // MARK: - Geocoding

    @Test func searchLocations() async throws {
        let stub = StubbedClient { _ in try .json("geocoding-istanbul") }
        let places = try await stub.client.searchLocations("  Istanbul ", count: 5, language: "tr", countryCode: "TR")

        #expect(places.count == 2)
        #expect(places.first?.name == "Istanbul")
        #expect(stub.lastPath == "/v1/search")
        #expect(stub.lastQueryValue("name") == "Istanbul")
        #expect(stub.lastQueryValue("count") == "5")
        #expect(stub.lastQueryValue("language") == "tr")
        #expect(stub.lastQueryValue("format") == "json")
        #expect(stub.lastQueryValue("countryCode") == "TR")
    }

    @Test func searchWithoutResults() async throws {
        let stub = StubbedClient { _ in try .json("geocoding-empty") }
        let places = try await stub.client.searchLocations("zzzzqq")

        #expect(places.isEmpty)
        #expect(stub.lastQueryValue("countryCode") == nil)
    }

    @Test func shortSearchesAreNotSent() async throws {
        let stub = StubbedClient { _ in try .json("geocoding-istanbul") }

        #expect(try await stub.client.searchLocations("I").isEmpty)
        #expect(try await stub.client.searchLocations("   ").isEmpty)
        #expect(stub.requests.isEmpty)

        await #expect(throws: OpenMeteoError.self) {
            try await stub.client.searchLocations("Istanbul", count: 0)
        }
        #expect(stub.requests.isEmpty)
    }

    @Test func plusSignsAreSentEncoded() async throws {
        let stub = StubbedClient { _ in try .json("geocoding-empty") }
        _ = try await stub.client.searchLocations("Saint+Denis")

        let url = try #require(stub.requests.last?.url)
        #expect((url.query ?? "").contains("Saint%2BDenis"))
        #expect(stub.lastQueryValue("name") == "Saint+Denis")
    }

    @Test func locationByID() async throws {
        let stub = StubbedClient { _ in try .json("location-745044") }
        let place = try await stub.client.location(id: 745044)

        #expect(place.name == "Istanbul")
        #expect(place.country == "Türkiye")
        #expect(stub.lastPath == "/v1/get")
        #expect(stub.lastQueryValue("id") == "745044")
        #expect(stub.lastQueryValue("language") == "en")
    }

    // MARK: - Errors

    @Test func apiErrorWithReason() async throws {
        let stub = StubbedClient { _ in try .json("error-invalid-variable", status: 400) }

        let error = await #expect(throws: OpenMeteoError.self) {
            try await stub.client.forecast(latitude: 41.01, longitude: 28.95)
        }
        let reason = "Cannot initialize WeatherVariable from invalid String value tempeture_2m for key hourly"
        #expect(error == .api(reason: reason, statusCode: 400))
        #expect(error?.errorDescription == reason)
    }

    @Test func apiErrorWithStatus200() async throws {
        let stub = StubbedClient { _ in try .json("error-invalid-variable") }

        let error = await #expect(throws: OpenMeteoError.self) {
            try await stub.client.forecast(latitude: 41.01, longitude: 28.95)
        }
        guard case let .api(_, status) = error else {
            Issue.record("Expected an API error, got \(String(describing: error))")
            return
        }
        #expect(status == 200)
    }

    @Test func httpErrorWithoutABody() async throws {
        let stub = StubbedClient { _ in .status(503, body: "Service Unavailable") }

        let error = await #expect(throws: OpenMeteoError.self) {
            try await stub.client.airQuality(latitude: 41.01, longitude: 28.95)
        }
        guard case let .http(status, url) = error else {
            Issue.record("Expected an HTTP error, got \(String(describing: error))")
            return
        }
        #expect(status == 503)
        #expect(url.path == "/v1/air-quality")
    }

    @Test func unexpectedJSON() async throws {
        let stub = StubbedClient { _ in StubResponse(status: 200, headers: [:], body: Data(#"{"hello":"world"}"#.utf8)) }

        let error = await #expect(throws: OpenMeteoError.self) {
            try await stub.client.forecast(latitude: 41.01, longitude: 28.95)
        }
        guard case let .decoding(type, _) = error else {
            Issue.record("Expected a decoding error, got \(String(describing: error))")
            return
        }
        #expect(type == "Forecast")
    }

    @Test func transportError() async throws {
        let stub = StubbedClient { _ in throw URLError(.notConnectedToInternet) }

        let error = await #expect(throws: OpenMeteoError.self) {
            try await stub.client.searchLocations("Istanbul")
        }
        guard case let .transport(urlError) = error else {
            Issue.record("Expected a transport error, got \(String(describing: error))")
            return
        }
        #expect(urlError.code == .notConnectedToInternet)
    }

    // MARK: - Endpoints

    @Test func endpoints() {
        #expect(OpenMeteoEndpoints.free.forecast.absoluteString == "https://api.open-meteo.com/v1/forecast")
        #expect(OpenMeteoEndpoints.free.archive.host == "archive-api.open-meteo.com")
        #expect(OpenMeteoEndpoints.free.airQuality.host == "air-quality-api.open-meteo.com")
        #expect(OpenMeteoEndpoints.free.geocoding.host == "geocoding-api.open-meteo.com")
        #expect(OpenMeteoEndpoints.customer.forecast.host == "customer-api.open-meteo.com")

        let local = OpenMeteoEndpoints.host(URL(string: "http://localhost:8080")!)
        #expect(local.forecast.absoluteString == "http://localhost:8080/v1/forecast")
        #expect(local.geocoding.appendingPathComponent("search").path == "/v1/search")

        let configuration = OpenMeteoConfiguration.customer(apiKey: "key")
        #expect(configuration.apiKey == "key")
        #expect(configuration.endpoints == .customer)
    }
}
