import Foundation

/// A variable that can be requested from an Open-Meteo API, by its API name.
public protocol OpenMeteoVariable: RawRepresentable, Hashable, Sendable, CaseIterable where RawValue == String {
    /// `true` for variables whose values are timestamps (`sunrise`, `sunset`) rather than numbers.
    var isTimestamp: Bool { get }
}

extension OpenMeteoVariable {
    public var isTimestamp: Bool { false }
}

/// A variable of the hourly forecast (`&hourly=`) and of the historical API's hourly data.
///
/// Every hourly variable is also available as a current condition (`&current=`), so the same enum is used for
/// both; see ``CurrentVariable``.
public enum HourlyVariable: String, OpenMeteoVariable {
    /// Air temperature 2 m above ground.
    case temperature2m = "temperature_2m"
    /// Relative humidity 2 m above ground, in percent.
    case relativeHumidity2m = "relative_humidity_2m"
    /// Dew point 2 m above ground.
    case dewPoint2m = "dew_point_2m"
    /// The "feels like" temperature, combining wind chill, humidity and solar radiation.
    case apparentTemperature = "apparent_temperature"
    /// The chance of more than 0.1 mm of precipitation, in percent.
    case precipitationProbability = "precipitation_probability"
    /// Total precipitation (rain, showers and snow) of the preceding hour.
    case precipitation
    /// Rain from large-scale weather systems of the preceding hour.
    case rain
    /// Showers from convective precipitation of the preceding hour.
    case showers
    /// Snowfall of the preceding hour, in centimeters (or inches).
    case snowfall
    /// Snow depth on the ground, in meters (or feet).
    case snowDepth = "snow_depth"
    /// The weather condition as a WMO code; see ``WeatherCode``.
    case weatherCode = "weather_code"
    /// Air pressure reduced to mean sea level, in hPa.
    case pressureMSL = "pressure_msl"
    /// Air pressure at the surface, in hPa.
    case surfacePressure = "surface_pressure"
    /// Total cloud cover, in percent.
    case cloudCover = "cloud_cover"
    /// Visibility, in meters (or feet).
    case visibility
    /// Wind speed 10 m above ground.
    case windSpeed10m = "wind_speed_10m"
    /// The direction the wind comes from, 10 m above ground, in degrees.
    case windDirection10m = "wind_direction_10m"
    /// Gusts 10 m above ground, the maximum of the preceding hour.
    case windGusts10m = "wind_gusts_10m"
    /// The UV index.
    case uvIndex = "uv_index"
    /// `1` during the day, `0` at night.
    case isDay = "is_day"
}

/// A variable of the current conditions (`&current=`). Open-Meteo accepts every hourly variable as a current one.
public typealias CurrentVariable = HourlyVariable

/// A variable of the daily forecast (`&daily=`) and of the historical API's daily data.
public enum DailyVariable: String, OpenMeteoVariable {
    /// The most severe weather condition of the day as a WMO code; see ``WeatherCode``.
    case weatherCode = "weather_code"
    /// The day's highest temperature 2 m above ground.
    case temperature2mMax = "temperature_2m_max"
    /// The day's lowest temperature 2 m above ground.
    case temperature2mMin = "temperature_2m_min"
    /// The day's highest apparent temperature.
    case apparentTemperatureMax = "apparent_temperature_max"
    /// The day's lowest apparent temperature.
    case apparentTemperatureMin = "apparent_temperature_min"
    /// Sunrise, local time.
    case sunrise
    /// Sunset, local time.
    case sunset
    /// The time between sunrise and sunset, in seconds.
    case daylightDuration = "daylight_duration"
    /// The time with direct sunshine, in seconds.
    case sunshineDuration = "sunshine_duration"
    /// The day's highest UV index.
    case uvIndexMax = "uv_index_max"
    /// The day's total precipitation.
    case precipitationSum = "precipitation_sum"
    /// The day's total rain.
    case rainSum = "rain_sum"
    /// The day's total showers.
    case showersSum = "showers_sum"
    /// The day's total snowfall.
    case snowfallSum = "snowfall_sum"
    /// The number of hours with precipitation.
    case precipitationHours = "precipitation_hours"
    /// The day's highest chance of precipitation, in percent.
    case precipitationProbabilityMax = "precipitation_probability_max"
    /// The day's highest wind speed 10 m above ground.
    case windSpeed10mMax = "wind_speed_10m_max"
    /// The day's highest gusts 10 m above ground.
    case windGusts10mMax = "wind_gusts_10m_max"
    /// The dominant direction the wind comes from, in degrees.
    case windDirection10mDominant = "wind_direction_10m_dominant"

    public var isTimestamp: Bool {
        self == .sunrise || self == .sunset
    }
}

/// A variable of the air-quality API (`&current=` and `&hourly=`).
public enum AirQualityVariable: String, OpenMeteoVariable {
    /// Particulate matter smaller than 10 µm, in µg/m³.
    case pm10
    /// Particulate matter smaller than 2.5 µm, in µg/m³.
    case pm2_5
    /// Carbon monoxide near the surface, in µg/m³.
    case carbonMonoxide = "carbon_monoxide"
    /// Nitrogen dioxide near the surface, in µg/m³.
    case nitrogenDioxide = "nitrogen_dioxide"
    /// Sulphur dioxide near the surface, in µg/m³.
    case sulphurDioxide = "sulphur_dioxide"
    /// Ozone near the surface, in µg/m³.
    case ozone
    /// Saharan dust near the surface, in µg/m³.
    case dust
    /// The UV index.
    case uvIndex = "uv_index"
    /// The European Air Quality Index (0 to 100 and above); see ``AirQualityLevel``.
    case europeanAQI = "european_aqi"
    /// The United States Air Quality Index (0 to 500); see ``AirQualityLevel``.
    case usAQI = "us_aqi"
}

extension Array where Element: OpenMeteoVariable {
    /// The API's comma-separated list, without duplicates and in the given order.
    var queryValue: String {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }.map(\.rawValue).joined(separator: ",")
    }
}
