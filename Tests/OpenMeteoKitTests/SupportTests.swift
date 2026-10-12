import Foundation
import Testing
@testable import OpenMeteoKit

@Suite("Weather codes")
struct WeatherCodeTests {
    @Test func everyCodeHasTextAndSymbols() {
        for code in WeatherCode.allCases {
            #expect(!code.description.isEmpty)
            #expect(!code.summary().isEmpty)
            #expect(code.symbolName(isDay: true).hasSuffix(".fill") || code == .snowGrains)
            #expect(!code.symbolName(isDay: false).isEmpty)
        }
        #expect(WeatherCode.allCases.count == 28)
    }

    @Test func codesFromResponseValues() {
        #expect(WeatherCode(3.0) == .overcast)
        #expect(WeatherCode(95) == .thunderstorm)
        #expect(WeatherCode(2.5) == nil)
        #expect(WeatherCode(4) == nil)
        #expect(WeatherCode(Double.nan) == nil)
        #expect(WeatherCode(nil) == nil)
        #expect(WeatherCode(rawValue: 80) == .slightRainShowers)
    }

    @Test func descriptions() {
        #expect(WeatherCode.clearSky.description == "Clear sky")
        #expect(WeatherCode.moderateRainShowers.description == "Moderate rain showers")
        #expect(WeatherCode.thunderstormWithHeavyHail.description == "Thunderstorm with heavy hail")
        #expect(WeatherCode.clearSky.summary(isDay: true) == "Sunny")
        #expect(WeatherCode.clearSky.summary(isDay: false) == "Clear")
        #expect(WeatherCode.overcast.summary() == "Cloudy")
    }

    @Test func dayAndNightSymbols() {
        #expect(WeatherCode.clearSky.symbolName(isDay: true) == "sun.max.fill")
        #expect(WeatherCode.clearSky.symbolName(isDay: false) == "moon.stars.fill")
        #expect(WeatherCode.partlyCloudy.symbolName(isDay: true) == "cloud.sun.fill")
        #expect(WeatherCode.partlyCloudy.symbolName(isDay: false) == "cloud.moon.fill")
        #expect(WeatherCode.slightRainShowers.symbolName(isDay: false) == "cloud.moon.rain.fill")
        #expect(WeatherCode.overcast.symbolName(isDay: true) == WeatherCode.overcast.symbolName(isDay: false))
        #expect(WeatherCode.heavyRain.symbolName() == "cloud.heavyrain.fill")
    }

    @Test func conditions() {
        #expect(WeatherCode.fog.condition == .fog)
        #expect(WeatherCode.lightFreezingDrizzle.condition == .freezingRain)
        #expect(WeatherCode.snowGrains.condition == .snow)
        #expect(WeatherCode.thunderstormWithSlightHail.condition == .thunderstorm)
        #expect(!WeatherCode.mainlyClear.hasPrecipitation)
        #expect(!WeatherCode.depositingRimeFog.hasPrecipitation)
        #expect(WeatherCode.denseDrizzle.hasPrecipitation)
        #expect(WeatherCode.heavySnowShowers.hasPrecipitation)
    }
}

@Suite("Air quality levels")
struct AirQualityLevelTests {
    @Test func europeanIndex() {
        #expect(AirQualityLevel(europeanAQI: 0).title == "Good")
        #expect(AirQualityLevel(europeanAQI: 20).title == "Good")
        #expect(AirQualityLevel(europeanAQI: 27).title == "Fair")
        #expect(AirQualityLevel(europeanAQI: 55).title == "Moderate")
        #expect(AirQualityLevel(europeanAQI: 61).title == "Poor")
        #expect(AirQualityLevel(europeanAQI: 99).title == "Very poor")
        #expect(AirQualityLevel(europeanAQI: 140).title == "Extremely poor")
        #expect(AirQualityLevel(europeanAQI: 140).severity == 5)
        #expect(AirQualityLevel(europeanAQI: 26.6).roundedValue == 27)
        #expect(AirQualityScale.european.abbreviation == "EAQI")
    }

    @Test func usIndex() {
        #expect(AirQualityLevel(usAQI: 44).title == "Good")
        #expect(AirQualityLevel(usAQI: 51).title == "Moderate")
        #expect(AirQualityLevel(usAQI: 120).title == "Unhealthy for sensitive groups")
        #expect(AirQualityLevel(usAQI: 120).shortTitle == "Sensitive")
        #expect(AirQualityLevel(usAQI: 180).shortTitle == "Unhealthy")
        #expect(AirQualityLevel(usAQI: 250).title == "Very unhealthy")
        #expect(AirQualityLevel(usAQI: 420).title == "Hazardous")
        #expect(AirQualityScale.us.abbreviation == "US AQI")
    }

    @Test func scalePosition() {
        // 27 is 35% of the way through "Fair", the second of six categories.
        #expect(abs(AirQualityLevel(europeanAQI: 27).scalePosition - 1.35 / 6) < 1e-9)
        #expect(abs(AirQualityLevel(usAQI: 44).scalePosition - 0.88 / 6) < 1e-9)
        #expect(AirQualityLevel(europeanAQI: 0).scalePosition == 0)
        #expect(AirQualityLevel(europeanAQI: 400).scalePosition == 1)
        #expect(AirQualityLevel(usAQI: -5).scalePosition == 0)
        #expect(AirQualityLevel(usAQI: .nan).scalePosition == 0)
    }
}

@Suite("Dates, directions and formatting")
struct SupportTests {
    @Test func calendarDates() throws {
        let day = try #require(CalendarDate("2026-10-08"))
        #expect(day == CalendarDate(year: 2026, month: 10, day: 8))
        #expect(day.description == "2026-10-08")
        #expect(CalendarDate("2026-1-08") == nil)
        #expect(CalendarDate("2026-13-01") == nil)
        #expect(CalendarDate("08.10.2026") == nil)
        #expect(CalendarDate(year: 2026, month: 10, day: 31).adding(days: 1) == CalendarDate(year: 2026, month: 11, day: 1))
        #expect(CalendarDate(year: 2026, month: 3, day: 1).adding(days: -1) == CalendarDate(year: 2026, month: 2, day: 28))
        #expect(CalendarDate(year: 2026, month: 9, day: 30) < day)
        #expect(CalendarDate(year: 987, month: 1, day: 2).description == "0987-01-02")
    }

    @Test func calendarDateCoding() throws {
        let encoded = try JSONEncoder().encode([CalendarDate(year: 2026, month: 10, day: 8)])
        #expect(String(decoding: encoded, as: UTF8.self) == #"["2026-10-08"]"#)
        let decoded = try JSONDecoder().decode([CalendarDate].self, from: encoded)
        #expect(decoded.first == CalendarDate(year: 2026, month: 10, day: 8))
    }

    @Test func calendarDateOfAnInstant() {
        // 23:30 in Istanbul is the 8th there; 01:00 on the 9th in Istanbul is still the 8th in UTC.
        let late = Fixture.date(2026, 10, 8, 23, 30)
        #expect(CalendarDate(late, in: Fixture.istanbul) == CalendarDate(year: 2026, month: 10, day: 8))
        let early = Fixture.date(2026, 10, 9, 1, 0)
        #expect(CalendarDate(early, in: TimeZone(identifier: "UTC")!) == CalendarDate(year: 2026, month: 10, day: 8))
        #expect(CalendarDate(year: 2026, month: 10, day: 8).startDate(in: Fixture.istanbul) == Fixture.date(2026, 10, 8))
    }

    @Test func openMeteoTimes() {
        #expect(OpenMeteoTime.date(from: "2026-10-08T14:00", in: Fixture.istanbul) == Fixture.date(2026, 10, 8, 14))
        #expect(OpenMeteoTime.date(from: "2026-10-08", in: Fixture.istanbul) == Fixture.date(2026, 10, 8))
        #expect(OpenMeteoTime.date(from: "2026-10-08T14:00:30", in: Fixture.istanbul) == Fixture.date(2026, 10, 8, 14).addingTimeInterval(30))
        #expect(OpenMeteoTime.date(from: "2026-10-08T25:00", in: Fixture.istanbul) == nil)
        #expect(OpenMeteoTime.date(from: "2026-10-08T14", in: Fixture.istanbul) == nil)
        #expect(OpenMeteoTime.date(from: "", in: Fixture.istanbul) == nil)
    }

    @Test func compassDirections() {
        #expect(CompassDirection(degrees: 0) == .n)
        #expect(CompassDirection(degrees: 36) == .ne)
        #expect(CompassDirection(degrees: 90) == .e)
        #expect(CompassDirection(degrees: 202.5) == .ssw)
        #expect(CompassDirection(degrees: 349) == .n)
        #expect(CompassDirection(degrees: -90) == .w)
        #expect(CompassDirection(degrees: 720) == .n)
        #expect(CompassDirection.sw.degrees == 225)
        #expect(CompassDirection.wnw.abbreviation == "WNW")
    }

    @Test func numbers() {
        #expect(WeatherFormat.temperature(21.6) == "22°")
        #expect(WeatherFormat.temperature(-0.4) == "0°")
        #expect(WeatherFormat.temperature(-3.5) == "-4°")
        #expect(WeatherFormat.temperature(nil) == "--")
        #expect(WeatherFormat.temperature(.infinity) == "--")
        #expect(WeatherFormat.temperature(21.6, unit: .celsius) == "22 °C")
        #expect(WeatherFormat.temperature(71.6, unit: .fahrenheit) == "72 °F")
        #expect(WeatherFormat.percent(59) == "59%")
        #expect(WeatherFormat.speed(14.8, unit: "km/h") == "15 km/h")
        #expect(WeatherFormat.wind(speed: 14.8, direction: 36, unit: "km/h") == "15 km/h NE")
        #expect(WeatherFormat.wind(speed: nil, direction: 36, unit: "km/h") == "--")
        #expect(WeatherFormat.uvIndex(3.45) == "3")
    }

    @Test func precipitationAmounts() {
        #expect(WeatherFormat.precipitation(0, unit: "mm") == "0 mm")
        #expect(WeatherFormat.precipitation(0.4, unit: "mm") == "0.4 mm")
        #expect(WeatherFormat.precipitation(4.26, unit: "mm") == "4.3 mm")
        #expect(WeatherFormat.precipitation(3.0, unit: "mm") == "3 mm")
        #expect(WeatherFormat.precipitation(11.8, unit: "mm") == "12 mm")
        #expect(WeatherFormat.precipitation(-1, unit: "mm") == "0 mm")
        #expect(WeatherFormat.precipitation(nil, unit: "inch") == "--")
    }

    @Test func otherQuantities() {
        #expect(WeatherFormat.uvCategory(2.4) == "Low")
        #expect(WeatherFormat.uvCategory(3.45) == "Moderate")
        #expect(WeatherFormat.uvCategory(6) == "High")
        #expect(WeatherFormat.uvCategory(9.6) == "Very high")
        #expect(WeatherFormat.uvCategory(11) == "Extreme")
        #expect(WeatherFormat.visibility(meters: 24_140) == "24 km")
        #expect(WeatherFormat.visibility(meters: 800) == "0.8 km")
        #expect(WeatherFormat.duration(seconds: 41_520) == "11 h 32 min")
        #expect(WeatherFormat.duration(seconds: 3_600) == "1 h")
        #expect(WeatherFormat.duration(seconds: 1_500) == "25 min")
    }

    @Test func weekdays() {
        let english = Locale(identifier: "en_US_POSIX")
        #expect(WeatherFormat.weekday(Fixture.date(2026, 10, 8), in: Fixture.istanbul, locale: english) == "Thu")
        #expect(WeatherFormat.fullWeekday(Fixture.date(2026, 10, 8), in: Fixture.istanbul, locale: english) == "Thursday")
        // The same instant is still Wednesday in New York.
        let newYork = TimeZone(identifier: "America/New_York")!
        #expect(WeatherFormat.weekday(Fixture.date(2026, 10, 8, 2), in: newYork, locale: english) == "Wed")
    }

    @Test func temperatureScale() throws {
        let forecast = try Fixture.decode(Forecast.self, from: "forecast-istanbul")
        let scale = TemperatureScale(days: forecast.dailyWeather)

        #expect(scale.lower == 12.6)
        #expect(scale.upper == 23.5)
        #expect(scale.position(of: 12.6) == 0)
        #expect(scale.position(of: 23.5) == 1)
        #expect(scale.position(of: 40) == 1)
        #expect(scale.position(of: -10) == 0)
        let span = scale.span(low: 15.8, high: 22.4)
        #expect(abs(span.lowerBound - 3.2 / 10.9) < 1e-9)
        #expect(abs(span.upperBound - 9.8 / 10.9) < 1e-9)
        // Reversed arguments give the same span.
        #expect(scale.span(low: 22.4, high: 15.8) == span)
    }

    @Test func degenerateTemperatureScales() {
        let flat = TemperatureScale(lower: 5, upper: 5)
        #expect(flat.lower == 4.5)
        #expect(flat.upper == 5.5)
        let reversed = TemperatureScale(lower: 30, upper: 10)
        #expect(reversed.lower == 10)
        #expect(reversed.upper == 30)
        let empty = TemperatureScale(days: [])
        #expect(empty.lower == 0)
        #expect(empty.upper == 1)
    }

    @Test func attribution() {
        #expect(OpenMeteoAttribution.text == "Weather data by Open-Meteo.com")
        #expect(OpenMeteoAttribution.url.host == "open-meteo.com")
        #expect(OpenMeteoAttribution.licenseName == "CC BY 4.0")
    }
}
