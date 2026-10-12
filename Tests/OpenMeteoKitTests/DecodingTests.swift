import Foundation
import Testing
@testable import OpenMeteoKit

@Suite("Decoding responses")
struct DecodingTests {
    // MARK: - Forecast

    @Test func forecastMetadata() throws {
        let forecast = try Fixture.decode(Forecast.self, from: "forecast-istanbul")

        #expect(forecast.latitude == 41.0)
        #expect(forecast.longitude == 28.940002)
        #expect(forecast.elevation == 37.0)
        #expect(forecast.utcOffsetSeconds == 10_800)
        #expect(forecast.timeZoneIdentifier == "Europe/Istanbul")
        #expect(forecast.timeZoneAbbreviation == "GMT+3")
        #expect(forecast.timeZone.identifier == "Europe/Istanbul")
        #expect(forecast.coordinate == Coordinate(latitude: 41.0, longitude: 28.940002))
    }

    @Test func currentConditions() throws {
        let forecast = try Fixture.decode(Forecast.self, from: "forecast-istanbul")
        let current = try #require(forecast.current)

        #expect(current.time == Fixture.date(2026, 10, 8, 14))
        #expect(current.interval == 900)
        #expect(current.temperature == 21.9)
        #expect(current.apparentTemperature == 20.7)
        #expect(current.relativeHumidity == 59)
        #expect(current.isDay)
        #expect(current.weatherCode == .partlyCloudy)
        #expect(current.cloudCover == 41)
        #expect(current.pressure == 1016.4)
        #expect(current.windSpeed == 14.8)
        #expect(current.windGusts == 29.2)
        #expect(current.weather.windCompassDirection == .ne)
        #expect(current.uvIndex == 3.45)
        #expect(current[.precipitation] == 0)
        #expect(current.unit(for: .temperature2m) == "°C")
        #expect(current.unit(for: .windSpeed10m) == "km/h")
    }

    @Test func hourlyColumnsBecomeRows() throws {
        let forecast = try Fixture.decode(Forecast.self, from: "forecast-istanbul")
        let hourly = try #require(forecast.hourly)

        #expect(hourly.count == 168)
        #expect(hourly.times.first == Fixture.date(2026, 10, 8, 0))
        #expect(hourly.times.last == Fixture.date(2026, 10, 14, 23))
        #expect(hourly[.temperature2m].count == 168)
        #expect(hourly.unit(for: .temperature2m) == "°C")
        #expect(hourly.variables.contains(.weatherCode))
        #expect(!hourly.variables.contains(.snowDepth))

        let rows = forecast.hourlyWeather
        #expect(rows.count == 168)
        let afternoon = rows[14]
        #expect(afternoon.time == Fixture.date(2026, 10, 8, 14))
        #expect(afternoon.temperature == 22.2)
        #expect(afternoon.weatherCode == .partlyCloudy)
        #expect(afternoon.precipitationProbability == 10)
        #expect(afternoon.isDay == true)
        // Not requested: nil, not zero.
        #expect(afternoon.snowfall == nil)
        #expect(afternoon.pressure == nil)

        let evening = rows[19]
        #expect(evening.isDay == false)
        #expect(evening.weatherCode == .mainlyClear)
        #expect(evening.uvIndex == 0)
    }

    @Test func upcomingHoursStartAtTheCurrentHour() throws {
        let forecast = try Fixture.decode(Forecast.self, from: "forecast-istanbul")
        let hours = forecast.upcomingHours(12)

        #expect(hours.count == 12)
        #expect(hours.first?.time == Fixture.date(2026, 10, 8, 14))
        #expect(hours.last?.time == Fixture.date(2026, 10, 9, 1))
        #expect(forecast.upcomingHours(0).isEmpty)
        // Near the end of the data there are fewer hours left.
        let late = try #require(forecast.hourly).rows(from: Fixture.date(2026, 10, 14, 22, 30), count: 24)
        #expect(late.count == 2)
    }

    @Test func dailyColumnsBecomeRows() throws {
        let forecast = try Fixture.decode(Forecast.self, from: "forecast-istanbul")
        let days = forecast.dailyWeather

        #expect(days.count == 7)
        let today = try #require(forecast.today)
        #expect(today == days[0])
        #expect(today.date == Fixture.date(2026, 10, 8))
        #expect(today.calendarDate(in: forecast.timeZone) == CalendarDate(year: 2026, month: 10, day: 8))
        #expect(today.temperatureMax == 22.4)
        #expect(today.temperatureMin == 15.8)
        #expect(today.sunrise == Fixture.date(2026, 10, 8, 7, 10))
        #expect(today.sunset == Fixture.date(2026, 10, 8, 18, 42))
        #expect(today.uvIndexMax == 4.15)
        #expect(today.precipitationProbabilityMax == 10)
        #expect(today.windDirectionDominant == 38)
        #expect(today.snowfallSum == nil)

        #expect(days[1].weatherCode == .slightRainShowers)
        #expect(days[2].weatherCode == .moderateRain)
        #expect(days[2].precipitationSum == 11.8)
        #expect(days[6].weatherCode == .thunderstorm)

        let daily = try #require(forecast.daily)
        #expect(daily.timestamps(.sunrise).count == 7)
        #expect(daily[.sunrise].isEmpty)
        #expect(daily.variables.contains(.sunset))
    }

    // MARK: - Historical

    @Test func archive() throws {
        let archive = try Fixture.decode(Forecast.self, from: "archive-istanbul")

        #expect(archive.current == nil)
        #expect(archive.hourly == nil)
        #expect(archive.hourlyWeather.isEmpty)
        let days = archive.dailyWeather
        #expect(days.count == 7)
        #expect(days.first?.date == Fixture.date(2026, 9, 1))
        #expect(days[3].weatherCode == .moderateDrizzle)
        #expect(days[3].precipitationSum == 3.4)
        #expect(days[6].sunset == Fixture.date(2026, 9, 7, 19, 25))
    }

    // MARK: - Air quality

    @Test func airQuality() throws {
        let air = try Fixture.decode(AirQuality.self, from: "air-quality-istanbul")

        #expect(air.timeZone.identifier == "Europe/Istanbul")
        #expect(air.currentInterval == 3600)
        let current = try #require(air.current)
        #expect(current.time == Fixture.date(2026, 10, 8, 14))
        #expect(current.europeanAQI == 27)
        #expect(current.usAQI == 44)
        #expect(current.pm10 == 19.9)
        #expect(current.pm2_5 == 11.0)
        #expect(current.ozone == nil)
        #expect(current.europeanLevel?.title == "Fair")
        #expect(current.usLevel?.title == "Good")
        #expect(air.currentUnits["european_aqi"] == "EAQI")

        let hourly = air.hourlyReadings
        #expect(hourly.count == 120)
        #expect(hourly[17].europeanAQI == 33)
        #expect(hourly[17].usLevel?.severity == 1)
    }

    // MARK: - Geocoding

    @Test func locations() throws {
        let response = try Fixture.decode(GeocodingResponse.self, from: "geocoding-istanbul")
        let results = try #require(response.results)

        #expect(results.count == 2)
        let city = results[0]
        #expect(city.id == 745044)
        #expect(city.name == "Istanbul")
        #expect(city.featureCode == "PPLA")
        #expect(city.countryCode == "TR")
        #expect(city.country == "Türkiye")
        #expect(city.admin1ID == 745042)
        #expect(city.population == 14_804_116)
        #expect(city.timeZone?.identifier == "Europe/Istanbul")
        #expect(city.coordinate == Coordinate(latitude: 41.01384, longitude: 28.94966))
        // The province has the city's name, so only the country is shown.
        #expect(city.regionDescription == "Türkiye")
        #expect(results[1].featureCode == "ADM1")
        #expect(results[1].admin1 == nil)
    }

    @Test func noResults() throws {
        let response = try Fixture.decode(GeocodingResponse.self, from: "geocoding-empty")
        #expect(response.results == nil)
    }

    @Test func regionDescription() {
        let ankara = Location(id: 1, name: "Çankaya", latitude: 39.9, longitude: 32.8, country: "Türkiye", admin1: "Ankara")
        #expect(ankara.regionDescription == "Ankara, Türkiye")
        let codeOnly = Location(id: 2, name: "Nowhere", latitude: 0, longitude: 0, countryCode: "XX")
        #expect(codeOnly.regionDescription == "XX")
    }

    // MARK: - Columnar edge cases

    @Test func nullValuesAndUnknownColumns() throws {
        let json = #"""
        {"latitude":52.52,"longitude":13.42,"utc_offset_seconds":0,"timezone":"GMT","timezone_abbreviation":"GMT",
         "hourly_units":{"time":"iso8601","temperature_2m":"°C","cape":"J/kg"},
         "hourly":{"time":["2026-10-08T00:00","2026-10-08T01:00"],"temperature_2m":[10.5,null],"cape":[0.0,12.5]}}
        """#
        let forecast = try JSONDecoder().decode(Forecast.self, from: Data(json.utf8))
        let hourly = try #require(forecast.hourly)

        #expect(hourly.value(.temperature2m, at: 0) == 10.5)
        #expect(hourly.value(.temperature2m, at: 1) == nil)
        #expect(hourly.value(.temperature2m, at: 5) == nil)
        #expect(hourly["cape"].count == 2)
        #expect(hourly["cape"][1] == 12.5)
        #expect(hourly.unit(for: .temperature2m) == "°C")
        #expect(forecast.hourlyWeather[1].temperature == nil)
        #expect(forecast.timeZone.secondsFromGMT() == 0)
    }

    @Test func unixTimestamps() throws {
        // timeformat=unixtime: every time is seconds since 1970, sunrise and sunset too.
        let json = #"""
        {"latitude":41.0,"longitude":28.94,"utc_offset_seconds":10800,"timezone":"Europe/Istanbul",
         "current":{"time":1791457200,"interval":900,"temperature_2m":21.9},
         "daily":{"time":[1791406800],"sunrise":[1791432600],"temperature_2m_max":[22.4]}}
        """#
        let forecast = try JSONDecoder().decode(Forecast.self, from: Data(json.utf8))

        #expect(forecast.current?.time == Date(timeIntervalSince1970: 1_791_457_200))
        let day = try #require(forecast.dailyWeather.first)
        #expect(day.date == Date(timeIntervalSince1970: 1_791_406_800))
        #expect(day.sunrise == Date(timeIntervalSince1970: 1_791_432_600))
        #expect(day.temperatureMax == 22.4)
    }

    @Test func unreadableTimeIsAnError() {
        let json = #"{"latitude":0,"longitude":0,"hourly":{"time":["yesterday"],"temperature_2m":[1.0]}}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Forecast.self, from: Data(json.utf8))
        }
    }

    @Test func indexContainingADate() throws {
        let forecast = try Fixture.decode(Forecast.self, from: "forecast-istanbul")
        let hourly = try #require(forecast.hourly)

        #expect(hourly.index(containing: Fixture.date(2026, 10, 8, 14, 45)) == 14)
        #expect(hourly.index(containing: Fixture.date(2026, 10, 8, 0)) == 0)
        #expect(hourly.index(containing: Fixture.date(2026, 10, 7, 23)) == nil)
        #expect(hourly.index(containing: Fixture.date(2026, 10, 20)) == 167)
    }
}
