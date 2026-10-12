import Foundation

/// `temperature_unit`.
public enum TemperatureUnit: String, CaseIterable, Sendable, Codable {
    /// Degrees Celsius, the API's default.
    case celsius
    /// Degrees Fahrenheit.
    case fahrenheit

    /// "°C" or "°F", as Open-Meteo writes it in `*_units`.
    public var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

/// `wind_speed_unit`.
public enum WindSpeedUnit: String, CaseIterable, Sendable, Codable {
    /// Kilometers per hour, the API's default.
    case kmh
    /// Miles per hour.
    case mph
    /// Meters per second.
    case ms
    /// Knots.
    case kn

    /// "km/h", "mp/h", "m/s" or "kn", as Open-Meteo writes it in `*_units`.
    public var symbol: String {
        switch self {
        case .kmh: return "km/h"
        case .mph: return "mp/h"
        case .ms: return "m/s"
        case .kn: return "kn"
        }
    }
}

/// `precipitation_unit`.
public enum PrecipitationUnit: String, CaseIterable, Sendable, Codable {
    /// Millimeters, the API's default. Snowfall is then in centimeters.
    case mm
    /// Inches, for precipitation and snowfall.
    case inch

    /// "mm" or "inch", as Open-Meteo writes it in `*_units`.
    public var symbol: String {
        switch self {
        case .mm: return "mm"
        case .inch: return "inch"
        }
    }
}

/// The units a forecast or historical response uses.
public struct WeatherUnits: Hashable, Sendable, Codable {
    public var temperature: TemperatureUnit
    public var windSpeed: WindSpeedUnit
    public var precipitation: PrecipitationUnit

    public init(
        temperature: TemperatureUnit = .celsius,
        windSpeed: WindSpeedUnit = .kmh,
        precipitation: PrecipitationUnit = .mm
    ) {
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.precipitation = precipitation
    }

    /// °C, km/h and mm: Open-Meteo's defaults.
    public static let metric = WeatherUnits()

    /// °F, mph and inches.
    public static let imperial = WeatherUnits(temperature: .fahrenheit, windSpeed: .mph, precipitation: .inch)

    /// Only the units that differ from the API's defaults, so URLs stay short.
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if temperature != .celsius {
            items.append(URLQueryItem(name: "temperature_unit", value: temperature.rawValue))
        }
        if windSpeed != .kmh {
            items.append(URLQueryItem(name: "wind_speed_unit", value: windSpeed.rawValue))
        }
        if precipitation != .mm {
            items.append(URLQueryItem(name: "precipitation_unit", value: precipitation.rawValue))
        }
        return items
    }
}

/// `timezone`: the time zone timestamps in the response are local to, and the one daily values are aggregated in.
public enum ForecastTimeZone: Hashable, Sendable {
    /// The time zone of the coordinates (`timezone=auto`). The default.
    case auto
    /// UTC (`timezone=GMT`), the API's own default.
    case gmt
    /// A time zone from the IANA database, such as `"Europe/Istanbul"`.
    case identifier(String)

    /// A Foundation time zone.
    public init(_ timeZone: TimeZone) {
        self = .identifier(timeZone.identifier)
    }

    var queryValue: String {
        switch self {
        case .auto: return "auto"
        case .gmt: return "GMT"
        case let .identifier(identifier): return identifier
        }
    }
}
