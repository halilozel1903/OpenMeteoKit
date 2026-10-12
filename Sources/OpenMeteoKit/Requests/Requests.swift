import Foundation

/// The parameters of a forecast (`/v1/forecast`).
///
/// ```swift
/// var request = ForecastRequest(latitude: 41.01, longitude: 28.95)   // current, hourly and daily presets
/// request.units = .imperial
/// request.forecastDays = 10
/// let forecast = try await client.forecast(request)
/// ```
public struct ForecastRequest: Hashable, Sendable {
    public var coordinate: Coordinate
    /// `current`: values for the current 15 minutes.
    public var current: [CurrentVariable]
    /// `hourly`: one value per hour.
    public var hourly: [HourlyVariable]
    /// `daily`: one value per day, aggregated in ``timeZone``.
    public var daily: [DailyVariable]
    public var units: WeatherUnits
    /// `timezone`; `.auto` uses the coordinate's time zone.
    public var timeZone: ForecastTimeZone
    /// `forecast_days`, 0 to 16; `nil` for the API's default of 7.
    public var forecastDays: Int?
    /// `past_days`, 0 to 92: days before today to include.
    public var pastDays: Int?
    /// `forecast_hours`: limits the hourly data to this many hours from the current hour.
    public var forecastHours: Int?
    /// `models`: weather models to use, such as `"ecmwf_ifs025"`; empty for Open-Meteo's best match.
    public var models: [String]

    public init(
        coordinate: Coordinate,
        current: [CurrentVariable] = ForecastRequest.defaultCurrent,
        hourly: [HourlyVariable] = ForecastRequest.defaultHourly,
        daily: [DailyVariable] = ForecastRequest.defaultDaily,
        units: WeatherUnits = .metric,
        timeZone: ForecastTimeZone = .auto,
        forecastDays: Int? = nil,
        pastDays: Int? = nil,
        forecastHours: Int? = nil,
        models: [String] = []
    ) {
        self.coordinate = coordinate
        self.current = current
        self.hourly = hourly
        self.daily = daily
        self.units = units
        self.timeZone = timeZone
        self.forecastDays = forecastDays
        self.pastDays = pastDays
        self.forecastHours = forecastHours
        self.models = models
    }

    public init(
        latitude: Double,
        longitude: Double,
        current: [CurrentVariable] = ForecastRequest.defaultCurrent,
        hourly: [HourlyVariable] = ForecastRequest.defaultHourly,
        daily: [DailyVariable] = ForecastRequest.defaultDaily,
        units: WeatherUnits = .metric,
        timeZone: ForecastTimeZone = .auto,
        forecastDays: Int? = nil,
        pastDays: Int? = nil
    ) {
        self.init(
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            current: current,
            hourly: hourly,
            daily: daily,
            units: units,
            timeZone: timeZone,
            forecastDays: forecastDays,
            pastDays: pastDays
        )
    }

    /// What a weather app shows for "now": temperature, feels like, humidity, day or night, precipitation,
    /// condition, wind and UV.
    public static let defaultCurrent: [CurrentVariable] = [
        .temperature2m, .apparentTemperature, .relativeHumidity2m, .isDay, .precipitation,
        .weatherCode, .cloudCover, .pressureMSL, .windSpeed10m, .windDirection10m, .windGusts10m, .uvIndex,
    ]

    /// What an hourly strip shows.
    public static let defaultHourly: [HourlyVariable] = [
        .temperature2m, .apparentTemperature, .precipitationProbability, .precipitation,
        .weatherCode, .windSpeed10m, .windDirection10m, .relativeHumidity2m, .uvIndex, .isDay,
    ]

    /// What a 7-day list shows.
    public static let defaultDaily: [DailyVariable] = [
        .weatherCode, .temperature2mMax, .temperature2mMin, .apparentTemperatureMax, .apparentTemperatureMin,
        .sunrise, .sunset, .uvIndexMax, .precipitationSum, .precipitationProbabilityMax, .windSpeed10mMax,
        .windDirection10mDominant,
    ]

    func validate() throws {
        if let forecastDays, !(0...16).contains(forecastDays) {
            throw OpenMeteoError.invalidRequest("forecast_days must be between 0 and 16, not \(forecastDays).")
        }
        if let pastDays, !(0...92).contains(pastDays) {
            throw OpenMeteoError.invalidRequest("past_days must be between 0 and 92, not \(pastDays).")
        }
        if let forecastHours, forecastHours < 0 {
            throw OpenMeteoError.invalidRequest("forecast_hours must not be negative.")
        }
        try coordinate.validate()
    }

    var queryItems: [URLQueryItem] {
        var items = coordinate.queryItems
        if !current.isEmpty { items.append(URLQueryItem(name: "current", value: current.queryValue)) }
        if !hourly.isEmpty { items.append(URLQueryItem(name: "hourly", value: hourly.queryValue)) }
        if !daily.isEmpty { items.append(URLQueryItem(name: "daily", value: daily.queryValue)) }
        items += units.queryItems
        items.append(URLQueryItem(name: "timezone", value: timeZone.queryValue))
        if let forecastDays { items.append(URLQueryItem(name: "forecast_days", value: String(forecastDays))) }
        if let pastDays { items.append(URLQueryItem(name: "past_days", value: String(pastDays))) }
        if let forecastHours { items.append(URLQueryItem(name: "forecast_hours", value: String(forecastHours))) }
        if !models.isEmpty { items.append(URLQueryItem(name: "models", value: models.joined(separator: ","))) }
        return items
    }
}

/// The parameters of a request to the historical weather API (`/v1/archive`), which goes back to 1940.
public struct HistoricalRequest: Hashable, Sendable {
    public var coordinate: Coordinate
    /// `start_date`, the first day.
    public var startDate: CalendarDate
    /// `end_date`, the last day (included).
    public var endDate: CalendarDate
    public var hourly: [HourlyVariable]
    public var daily: [DailyVariable]
    public var units: WeatherUnits
    public var timeZone: ForecastTimeZone

    public init(
        coordinate: Coordinate,
        startDate: CalendarDate,
        endDate: CalendarDate,
        hourly: [HourlyVariable] = [],
        daily: [DailyVariable] = [.weatherCode, .temperature2mMax, .temperature2mMin, .precipitationSum],
        units: WeatherUnits = .metric,
        timeZone: ForecastTimeZone = .auto
    ) {
        self.coordinate = coordinate
        self.startDate = startDate
        self.endDate = endDate
        self.hourly = hourly
        self.daily = daily
        self.units = units
        self.timeZone = timeZone
    }

    func validate() throws {
        if endDate < startDate {
            throw OpenMeteoError.invalidRequest("end_date \(endDate) is before start_date \(startDate).")
        }
        if hourly.isEmpty && daily.isEmpty {
            throw OpenMeteoError.invalidRequest("Request at least one hourly or daily variable.")
        }
        try coordinate.validate()
    }

    var queryItems: [URLQueryItem] {
        var items = coordinate.queryItems
        items.append(URLQueryItem(name: "start_date", value: startDate.description))
        items.append(URLQueryItem(name: "end_date", value: endDate.description))
        if !hourly.isEmpty { items.append(URLQueryItem(name: "hourly", value: hourly.queryValue)) }
        if !daily.isEmpty { items.append(URLQueryItem(name: "daily", value: daily.queryValue)) }
        items += units.queryItems
        items.append(URLQueryItem(name: "timezone", value: timeZone.queryValue))
        return items
    }
}

/// `domains` of the air-quality API.
public enum AirQualityDomain: String, CaseIterable, Sendable {
    /// Europe at 11 km where available, global at 45 km elsewhere. The default.
    case auto
    /// CAMS European air quality forecast, 11 km.
    case camsEurope = "cams_europe"
    /// CAMS global atmospheric composition forecast, 45 km.
    case camsGlobal = "cams_global"
}

/// The parameters of an air-quality request (`/v1/air-quality`).
public struct AirQualityRequest: Hashable, Sendable {
    public var coordinate: Coordinate
    public var current: [AirQualityVariable]
    public var hourly: [AirQualityVariable]
    public var timeZone: ForecastTimeZone
    /// `forecast_days`, 0 to 7; `nil` for the API's default of 5.
    public var forecastDays: Int?
    /// `past_days`, 0 to 92.
    public var pastDays: Int?
    public var domain: AirQualityDomain

    public init(
        coordinate: Coordinate,
        current: [AirQualityVariable] = AirQualityRequest.defaultVariables,
        hourly: [AirQualityVariable] = AirQualityRequest.defaultVariables,
        timeZone: ForecastTimeZone = .auto,
        forecastDays: Int? = nil,
        pastDays: Int? = nil,
        domain: AirQualityDomain = .auto
    ) {
        self.coordinate = coordinate
        self.current = current
        self.hourly = hourly
        self.timeZone = timeZone
        self.forecastDays = forecastDays
        self.pastDays = pastDays
        self.domain = domain
    }

    /// Both indexes and the particulate matter they are mostly driven by.
    public static let defaultVariables: [AirQualityVariable] = [.europeanAQI, .usAQI, .pm10, .pm2_5]

    func validate() throws {
        if let forecastDays, !(0...7).contains(forecastDays) {
            throw OpenMeteoError.invalidRequest("forecast_days must be between 0 and 7, not \(forecastDays).")
        }
        if let pastDays, !(0...92).contains(pastDays) {
            throw OpenMeteoError.invalidRequest("past_days must be between 0 and 92, not \(pastDays).")
        }
        try coordinate.validate()
    }

    var queryItems: [URLQueryItem] {
        var items = coordinate.queryItems
        if !current.isEmpty { items.append(URLQueryItem(name: "current", value: current.queryValue)) }
        if !hourly.isEmpty { items.append(URLQueryItem(name: "hourly", value: hourly.queryValue)) }
        items.append(URLQueryItem(name: "timezone", value: timeZone.queryValue))
        if let forecastDays { items.append(URLQueryItem(name: "forecast_days", value: String(forecastDays))) }
        if let pastDays { items.append(URLQueryItem(name: "past_days", value: String(pastDays))) }
        if domain != .auto { items.append(URLQueryItem(name: "domains", value: domain.rawValue)) }
        return items
    }
}

extension Coordinate {
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
        ]
    }

    func validate() throws {
        guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw OpenMeteoError.invalidRequest("(\(latitude), \(longitude)) is not a valid coordinate.")
        }
    }
}
