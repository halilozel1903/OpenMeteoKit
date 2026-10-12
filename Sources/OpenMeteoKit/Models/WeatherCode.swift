import Foundation

/// A WMO weather interpretation code (WW), as Open-Meteo returns it in `weather_code`.
///
/// ```swift
/// let code = WeatherCode(rawValue: 80)       // .slightRainShowers
/// code?.description                         // "Slight rain showers"
/// code?.symbolName(isDay: false)            // "cloud.moon.rain.fill"
/// ```
public enum WeatherCode: Int, CaseIterable, Sendable, Codable, CustomStringConvertible {
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case lightDrizzle = 51
    case moderateDrizzle = 53
    case denseDrizzle = 55
    case lightFreezingDrizzle = 56
    case denseFreezingDrizzle = 57
    case slightRain = 61
    case moderateRain = 63
    case heavyRain = 65
    case lightFreezingRain = 66
    case heavyFreezingRain = 67
    case slightSnowfall = 71
    case moderateSnowfall = 73
    case heavySnowfall = 75
    case snowGrains = 77
    case slightRainShowers = 80
    case moderateRainShowers = 81
    case violentRainShowers = 82
    case slightSnowShowers = 85
    case heavySnowShowers = 86
    case thunderstorm = 95
    case thunderstormWithSlightHail = 96
    case thunderstormWithHeavyHail = 99

    /// The code of a value as it appears in a response (`3` or `3.0`), or `nil` for a missing or unknown code.
    public init?(_ value: Double?) {
        guard let value, value.isFinite, value == value.rounded() else { return nil }
        self.init(rawValue: Int(value))
    }

    /// The WMO description, such as "Moderate rain showers".
    public var description: String {
        switch self {
        case .clearSky: return "Clear sky"
        case .mainlyClear: return "Mainly clear"
        case .partlyCloudy: return "Partly cloudy"
        case .overcast: return "Overcast"
        case .fog: return "Fog"
        case .depositingRimeFog: return "Depositing rime fog"
        case .lightDrizzle: return "Light drizzle"
        case .moderateDrizzle: return "Moderate drizzle"
        case .denseDrizzle: return "Dense drizzle"
        case .lightFreezingDrizzle: return "Light freezing drizzle"
        case .denseFreezingDrizzle: return "Dense freezing drizzle"
        case .slightRain: return "Slight rain"
        case .moderateRain: return "Moderate rain"
        case .heavyRain: return "Heavy rain"
        case .lightFreezingRain: return "Light freezing rain"
        case .heavyFreezingRain: return "Heavy freezing rain"
        case .slightSnowfall: return "Slight snowfall"
        case .moderateSnowfall: return "Moderate snowfall"
        case .heavySnowfall: return "Heavy snowfall"
        case .snowGrains: return "Snow grains"
        case .slightRainShowers: return "Slight rain showers"
        case .moderateRainShowers: return "Moderate rain showers"
        case .violentRainShowers: return "Violent rain showers"
        case .slightSnowShowers: return "Slight snow showers"
        case .heavySnowShowers: return "Heavy snow showers"
        case .thunderstorm: return "Thunderstorm"
        case .thunderstormWithSlightHail: return "Thunderstorm with slight hail"
        case .thunderstormWithHeavyHail: return "Thunderstorm with heavy hail"
        }
    }

    /// A short everyday summary for a forecast, such as "Sunny" by day and "Clear" by night.
    public func summary(isDay: Bool = true) -> String {
        switch self {
        case .clearSky: return isDay ? "Sunny" : "Clear"
        case .mainlyClear: return isDay ? "Mostly sunny" : "Mostly clear"
        case .partlyCloudy: return "Partly cloudy"
        case .overcast: return "Cloudy"
        case .fog, .depositingRimeFog: return "Fog"
        case .lightDrizzle, .moderateDrizzle, .denseDrizzle: return "Drizzle"
        case .lightFreezingDrizzle, .denseFreezingDrizzle: return "Freezing drizzle"
        case .slightRain: return "Light rain"
        case .moderateRain: return "Rain"
        case .heavyRain: return "Heavy rain"
        case .lightFreezingRain, .heavyFreezingRain: return "Freezing rain"
        case .slightSnowfall: return "Light snow"
        case .moderateSnowfall: return "Snow"
        case .heavySnowfall: return "Heavy snow"
        case .snowGrains: return "Snow grains"
        case .slightRainShowers, .moderateRainShowers: return "Showers"
        case .violentRainShowers: return "Heavy showers"
        case .slightSnowShowers, .heavySnowShowers: return "Snow showers"
        case .thunderstorm: return "Thunderstorms"
        case .thunderstormWithSlightHail, .thunderstormWithHeavyHail: return "Thunderstorms with hail"
        }
    }

    /// The SF Symbol for the condition, by day or by night. Every name is a `.fill` symbol that supports
    /// multicolor rendering.
    public func symbolName(isDay: Bool = true) -> String {
        switch self {
        case .clearSky: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case .mainlyClear: return isDay ? "sun.min.fill" : "moon.fill"
        case .partlyCloudy: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .overcast: return "cloud.fill"
        case .fog, .depositingRimeFog: return "cloud.fog.fill"
        case .lightDrizzle, .moderateDrizzle, .denseDrizzle: return "cloud.drizzle.fill"
        case .lightFreezingDrizzle, .denseFreezingDrizzle, .lightFreezingRain, .heavyFreezingRain: return "cloud.sleet.fill"
        case .slightRain, .moderateRain: return "cloud.rain.fill"
        case .heavyRain, .violentRainShowers: return "cloud.heavyrain.fill"
        case .slightSnowfall, .moderateSnowfall, .heavySnowfall, .slightSnowShowers, .heavySnowShowers: return "cloud.snow.fill"
        case .snowGrains: return "snowflake"
        case .slightRainShowers, .moderateRainShowers: return isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case .thunderstorm: return isDay ? "cloud.sun.bolt.fill" : "cloud.moon.bolt.fill"
        case .thunderstormWithSlightHail, .thunderstormWithHeavyHail: return "cloud.hail.fill"
        }
    }

    /// The broad kind of weather, for choosing colors and backgrounds.
    public var condition: WeatherCondition {
        switch self {
        case .clearSky, .mainlyClear: return .clear
        case .partlyCloudy: return .partlyCloudy
        case .overcast: return .cloudy
        case .fog, .depositingRimeFog: return .fog
        case .lightDrizzle, .moderateDrizzle, .denseDrizzle: return .drizzle
        case .slightRain, .moderateRain, .heavyRain, .slightRainShowers, .moderateRainShowers, .violentRainShowers: return .rain
        case .lightFreezingDrizzle, .denseFreezingDrizzle, .lightFreezingRain, .heavyFreezingRain: return .freezingRain
        case .slightSnowfall, .moderateSnowfall, .heavySnowfall, .snowGrains, .slightSnowShowers, .heavySnowShowers: return .snow
        case .thunderstorm, .thunderstormWithSlightHail, .thunderstormWithHeavyHail: return .thunderstorm
        }
    }

    /// `true` when rain, drizzle, snow or hail falls.
    public var hasPrecipitation: Bool {
        switch condition {
        case .clear, .partlyCloudy, .cloudy, .fog: return false
        case .drizzle, .rain, .freezingRain, .snow, .thunderstorm: return true
        }
    }
}

/// A broad kind of weather, grouping the WMO codes.
public enum WeatherCondition: String, CaseIterable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case freezingRain
    case snow
    case thunderstorm
}
