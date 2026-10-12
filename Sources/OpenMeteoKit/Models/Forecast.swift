import Foundation

/// A coordinate in WGS84 degrees.
public struct Coordinate: Hashable, Sendable, Codable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// A response of the forecast API (`/v1/forecast`) or of the historical API (`/v1/archive`).
///
/// ```swift
/// let forecast = try await client.forecast(latitude: 41.01, longitude: 28.95,
///                                          current: [.temperature2m, .weatherCode, .isDay],
///                                          hourly: [.temperature2m, .weatherCode],
///                                          daily: [.temperature2mMax, .temperature2mMin, .sunrise])
/// forecast.current?.temperature                  // 21.6
/// forecast.hourlyWeather.first?.weatherCode      // .mainlyClear
/// forecast.dailyWeather.first?.sunrise           // Date
/// ```
public struct Forecast: Hashable, Sendable, Decodable {
    /// The latitude of the grid cell the data is for, which can differ slightly from the one requested.
    public let latitude: Double
    /// The longitude of the grid cell the data is for.
    public let longitude: Double
    /// The elevation used for statistical downscaling, in meters.
    public let elevation: Double?
    /// How long Open-Meteo took to generate the response, in milliseconds.
    public let generationTimeMilliseconds: Double?
    /// The offset of the response's time zone from UTC, in seconds.
    public let utcOffsetSeconds: Int
    /// The time zone of the response, such as `"Europe/Istanbul"` or `"GMT"`.
    public let timeZoneIdentifier: String
    /// The abbreviation of the time zone, such as `"GMT+3"`.
    public let timeZoneAbbreviation: String?
    /// The current conditions, when `current` variables were requested.
    public let current: CurrentWeather?
    /// The hourly columns, when `hourly` variables were requested.
    public let hourly: HourlySeries?
    /// The daily columns, when `daily` variables were requested.
    public let daily: DailySeries?

    /// The coordinate of the grid cell.
    public var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }

    /// The response's time zone; every time in it is local to this zone. Use it to format times and days.
    public var timeZone: TimeZone {
        ResponseTimeZone.make(identifier: timeZoneIdentifier, offset: utcOffsetSeconds)
    }

    /// The hourly rows; empty without `hourly` variables.
    public var hourlyWeather: [HourlyWeather] {
        hourly?.rows ?? []
    }

    /// The daily rows; empty without `daily` variables.
    public var dailyWeather: [DailyWeather] {
        daily?.rows ?? []
    }

    /// Up to `count` hourly rows starting with the current hour (the hour of ``current``, or now).
    public func upcomingHours(_ count: Int = 24) -> [HourlyWeather] {
        hourly?.rows(from: current?.time ?? Date(), count: count) ?? []
    }

    /// The daily row for the day of the current conditions (or today).
    public var today: DailyWeather? {
        let reference = current?.time ?? Date()
        let day = CalendarDate(reference, in: timeZone)
        return dailyWeather.first { $0.calendarDate(in: timeZone) == day }
    }

    public init(
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil,
        generationTimeMilliseconds: Double? = nil,
        utcOffsetSeconds: Int = 0,
        timeZoneIdentifier: String = "GMT",
        timeZoneAbbreviation: String? = "GMT",
        current: CurrentWeather? = nil,
        hourly: HourlySeries? = nil,
        daily: DailySeries? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.generationTimeMilliseconds = generationTimeMilliseconds
        self.utcOffsetSeconds = utcOffsetSeconds
        self.timeZoneIdentifier = timeZoneIdentifier
        self.timeZoneAbbreviation = timeZoneAbbreviation
        self.current = current
        self.hourly = hourly
        self.daily = daily
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case elevation
        case generationTime = "generationtime_ms"
        case utcOffsetSeconds = "utc_offset_seconds"
        case timezone
        case timezoneAbbreviation = "timezone_abbreviation"
        case currentUnits = "current_units"
        case current
        case hourlyUnits = "hourly_units"
        case hourly
        case dailyUnits = "daily_units"
        case daily
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        elevation = try container.decodeIfPresent(Double.self, forKey: .elevation)
        generationTimeMilliseconds = try container.decodeIfPresent(Double.self, forKey: .generationTime)
        utcOffsetSeconds = try container.decodeIfPresent(Int.self, forKey: .utcOffsetSeconds) ?? 0
        timeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .timezone) ?? "GMT"
        timeZoneAbbreviation = try container.decodeIfPresent(String.self, forKey: .timezoneAbbreviation)
        let zone = ResponseTimeZone.make(identifier: timeZoneIdentifier, offset: utcOffsetSeconds)

        if let raw = try container.decodeIfPresent(RawSnapshot.self, forKey: .current) {
            let units = try container.decodeIfPresent([String: String].self, forKey: .currentUnits) ?? [:]
            let time = try raw.date(in: zone, codingPath: container.codingPath + [CodingKeys.current as any CodingKey])
            current = CurrentWeather(
                time: time,
                interval: raw.interval,
                values: raw.numbers,
                units: units
            )
        } else {
            current = nil
        }
        if let raw = try container.decodeIfPresent(RawColumns.self, forKey: .hourly) {
            let units = try container.decodeIfPresent([String: String].self, forKey: .hourlyUnits) ?? [:]
            hourly = try HourlySeries(raw: raw, units: units, timeZone: zone)
        } else {
            hourly = nil
        }
        if let raw = try container.decodeIfPresent(RawColumns.self, forKey: .daily) {
            let units = try container.decodeIfPresent([String: String].self, forKey: .dailyUnits) ?? [:]
            daily = try DailySeries(raw: raw, units: units, timeZone: zone)
        } else {
            daily = nil
        }
    }
}

/// A response of the air-quality API (`/v1/air-quality`).
public struct AirQuality: Hashable, Sendable, Decodable {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double?
    public let generationTimeMilliseconds: Double?
    public let utcOffsetSeconds: Int
    public let timeZoneIdentifier: String
    public let timeZoneAbbreviation: String?
    /// The current values, when `current` variables were requested.
    public let current: AirQualityReading?
    /// The interval of the current values, in seconds (3600: air quality is hourly).
    public let currentInterval: Int?
    /// The units of the current values, by API name.
    public let currentUnits: [String: String]
    /// The hourly columns, when `hourly` variables were requested.
    public let hourly: AirQualitySeries?

    /// The response's time zone.
    public var timeZone: TimeZone {
        ResponseTimeZone.make(identifier: timeZoneIdentifier, offset: utcOffsetSeconds)
    }

    /// The hourly rows; empty without `hourly` variables.
    public var hourlyReadings: [AirQualityReading] {
        hourly?.rows ?? []
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case elevation
        case generationTime = "generationtime_ms"
        case utcOffsetSeconds = "utc_offset_seconds"
        case timezone
        case timezoneAbbreviation = "timezone_abbreviation"
        case currentUnits = "current_units"
        case current
        case hourlyUnits = "hourly_units"
        case hourly
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        elevation = try container.decodeIfPresent(Double.self, forKey: .elevation)
        generationTimeMilliseconds = try container.decodeIfPresent(Double.self, forKey: .generationTime)
        utcOffsetSeconds = try container.decodeIfPresent(Int.self, forKey: .utcOffsetSeconds) ?? 0
        timeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .timezone) ?? "GMT"
        timeZoneAbbreviation = try container.decodeIfPresent(String.self, forKey: .timezoneAbbreviation)
        let zone = ResponseTimeZone.make(identifier: timeZoneIdentifier, offset: utcOffsetSeconds)

        currentUnits = try container.decodeIfPresent([String: String].self, forKey: .currentUnits) ?? [:]
        if let raw = try container.decodeIfPresent(RawSnapshot.self, forKey: .current) {
            let time = try raw.date(in: zone, codingPath: container.codingPath + [CodingKeys.current as any CodingKey])
            let numbers = raw.numbers
            current = AirQualityReading(time: time) { numbers[$0.rawValue] }
            currentInterval = raw.interval
        } else {
            current = nil
            currentInterval = nil
        }
        if let raw = try container.decodeIfPresent(RawColumns.self, forKey: .hourly) {
            let units = try container.decodeIfPresent([String: String].self, forKey: .hourlyUnits) ?? [:]
            hourly = try AirQualitySeries(raw: raw, units: units, timeZone: zone)
        } else {
            hourly = nil
        }
    }
}

enum ResponseTimeZone {
    /// The zone named in the response, falling back to its fixed UTC offset.
    static func make(identifier: String, offset: Int) -> TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone(secondsFromGMT: offset) ?? .gmt
    }
}
