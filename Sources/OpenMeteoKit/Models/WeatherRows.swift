import Foundation

/// The weather of one hour: one row of the `hourly` columns.
///
/// Properties are `nil` when the variable was not requested or Open-Meteo has no value for that hour. Units are
/// the ones of the request (°C, km/h and mm by default); see ``TimeSeries/units``.
public struct HourlyWeather: Hashable, Sendable, Identifiable {
    /// The start of the hour.
    public let time: Date
    /// `temperature_2m`.
    public let temperature: Double?
    /// `apparent_temperature`, the "feels like" temperature.
    public let apparentTemperature: Double?
    /// `relative_humidity_2m`, in percent.
    public let relativeHumidity: Double?
    /// `dew_point_2m`.
    public let dewPoint: Double?
    /// `precipitation_probability`, in percent.
    public let precipitationProbability: Double?
    /// `precipitation` of the preceding hour.
    public let precipitation: Double?
    /// `rain` of the preceding hour.
    public let rain: Double?
    /// `showers` of the preceding hour.
    public let showers: Double?
    /// `snowfall` of the preceding hour.
    public let snowfall: Double?
    /// `weather_code`.
    public let weatherCode: WeatherCode?
    /// `cloud_cover`, in percent.
    public let cloudCover: Double?
    /// `pressure_msl`, in hPa.
    public let pressure: Double?
    /// `visibility`.
    public let visibility: Double?
    /// `wind_speed_10m`.
    public let windSpeed: Double?
    /// `wind_direction_10m`, where the wind comes from, in degrees.
    public let windDirection: Double?
    /// `wind_gusts_10m`.
    public let windGusts: Double?
    /// `uv_index`.
    public let uvIndex: Double?
    /// `is_day`; `nil` when it was not requested.
    public let isDay: Bool?

    public var id: Date { time }

    /// A row from a lookup of each variable's value.
    public init(time: Date, value: (HourlyVariable) -> Double?) {
        self.time = time
        temperature = value(.temperature2m)
        apparentTemperature = value(.apparentTemperature)
        relativeHumidity = value(.relativeHumidity2m)
        dewPoint = value(.dewPoint2m)
        precipitationProbability = value(.precipitationProbability)
        precipitation = value(.precipitation)
        rain = value(.rain)
        showers = value(.showers)
        snowfall = value(.snowfall)
        weatherCode = WeatherCode(value(.weatherCode))
        cloudCover = value(.cloudCover)
        pressure = value(.pressureMSL)
        visibility = value(.visibility)
        windSpeed = value(.windSpeed10m)
        windDirection = value(.windDirection10m)
        windGusts = value(.windGusts10m)
        uvIndex = value(.uvIndex)
        isDay = value(.isDay).map { $0 != 0 }
    }

    /// The compass point the wind comes from.
    public var windCompassDirection: CompassDirection? {
        windDirection.map { CompassDirection(degrees: $0) }
    }
}

/// The current conditions: the `current` object of a forecast.
///
/// Open-Meteo computes them from 15-minutely data, so ``time`` is a multiple of ``interval`` (900 seconds).
public struct CurrentWeather: Hashable, Sendable {
    /// When the values are for.
    public let time: Date
    /// The length of the period the values describe, in seconds.
    public let interval: Int?
    /// The values, read like an hourly row.
    public let weather: HourlyWeather
    /// Every value by API name, including variables this package has no case for.
    public let values: [String: Double]
    /// The unit of each variable, by API name, from `current_units`.
    public let units: [String: String]

    public init(time: Date, interval: Int?, values: [String: Double], units: [String: String] = [:]) {
        self.time = time
        self.interval = interval
        self.values = values
        self.units = units
        weather = HourlyWeather(time: time) { values[$0.rawValue] }
    }

    /// The value of `variable`.
    public subscript(variable: CurrentVariable) -> Double? {
        values[variable.rawValue]
    }

    /// The unit of `variable`, such as `"°C"`.
    public func unit(for variable: CurrentVariable) -> String? {
        units[variable.rawValue]
    }

    public var temperature: Double? { weather.temperature }
    public var apparentTemperature: Double? { weather.apparentTemperature }
    public var relativeHumidity: Double? { weather.relativeHumidity }
    public var precipitation: Double? { weather.precipitation }
    public var precipitationProbability: Double? { weather.precipitationProbability }
    public var weatherCode: WeatherCode? { weather.weatherCode }
    public var cloudCover: Double? { weather.cloudCover }
    public var pressure: Double? { weather.pressure }
    public var windSpeed: Double? { weather.windSpeed }
    public var windDirection: Double? { weather.windDirection }
    public var windGusts: Double? { weather.windGusts }
    public var uvIndex: Double? { weather.uvIndex }
    /// `true` by day; `true` as well when `is_day` was not requested.
    public var isDay: Bool { weather.isDay ?? true }
}

/// The weather of one day: one row of the `daily` columns.
public struct DailyWeather: Hashable, Sendable, Identifiable {
    /// The start of the day, in the response's time zone.
    public let date: Date
    /// `weather_code`, the most severe condition of the day.
    public let weatherCode: WeatherCode?
    /// `temperature_2m_max`.
    public let temperatureMax: Double?
    /// `temperature_2m_min`.
    public let temperatureMin: Double?
    /// `apparent_temperature_max`.
    public let apparentTemperatureMax: Double?
    /// `apparent_temperature_min`.
    public let apparentTemperatureMin: Double?
    /// `sunrise`.
    public let sunrise: Date?
    /// `sunset`.
    public let sunset: Date?
    /// `daylight_duration`, in seconds.
    public let daylightDuration: TimeInterval?
    /// `sunshine_duration`, in seconds.
    public let sunshineDuration: TimeInterval?
    /// `uv_index_max`.
    public let uvIndexMax: Double?
    /// `precipitation_sum`.
    public let precipitationSum: Double?
    /// `rain_sum`.
    public let rainSum: Double?
    /// `showers_sum`.
    public let showersSum: Double?
    /// `snowfall_sum`.
    public let snowfallSum: Double?
    /// `precipitation_hours`.
    public let precipitationHours: Double?
    /// `precipitation_probability_max`, in percent.
    public let precipitationProbabilityMax: Double?
    /// `wind_speed_10m_max`.
    public let windSpeedMax: Double?
    /// `wind_gusts_10m_max`.
    public let windGustsMax: Double?
    /// `wind_direction_10m_dominant`, in degrees.
    public let windDirectionDominant: Double?

    public var id: Date { date }

    /// A row from lookups of each variable's value and timestamp.
    public init(date: Date, value: (DailyVariable) -> Double?, timestamp: (DailyVariable) -> Date?) {
        self.date = date
        weatherCode = WeatherCode(value(.weatherCode))
        temperatureMax = value(.temperature2mMax)
        temperatureMin = value(.temperature2mMin)
        apparentTemperatureMax = value(.apparentTemperatureMax)
        apparentTemperatureMin = value(.apparentTemperatureMin)
        sunrise = timestamp(.sunrise)
        sunset = timestamp(.sunset)
        daylightDuration = value(.daylightDuration)
        sunshineDuration = value(.sunshineDuration)
        uvIndexMax = value(.uvIndexMax)
        precipitationSum = value(.precipitationSum)
        rainSum = value(.rainSum)
        showersSum = value(.showersSum)
        snowfallSum = value(.snowfallSum)
        precipitationHours = value(.precipitationHours)
        precipitationProbabilityMax = value(.precipitationProbabilityMax)
        windSpeedMax = value(.windSpeed10mMax)
        windGustsMax = value(.windGusts10mMax)
        windDirectionDominant = value(.windDirection10mDominant)
    }

    /// The day as a calendar date in `timeZone` (pass the response's ``Forecast/timeZone``).
    public func calendarDate(in timeZone: TimeZone) -> CalendarDate {
        CalendarDate(date, in: timeZone)
    }
}

/// The air quality of one hour: one row of the air-quality API's `hourly` columns, or its `current` values.
public struct AirQualityReading: Hashable, Sendable, Identifiable {
    public let time: Date
    /// `pm10`, in µg/m³.
    public let pm10: Double?
    /// `pm2_5`, in µg/m³.
    public let pm2_5: Double?
    /// `carbon_monoxide`, in µg/m³.
    public let carbonMonoxide: Double?
    /// `nitrogen_dioxide`, in µg/m³.
    public let nitrogenDioxide: Double?
    /// `sulphur_dioxide`, in µg/m³.
    public let sulphurDioxide: Double?
    /// `ozone`, in µg/m³.
    public let ozone: Double?
    /// `dust`, in µg/m³.
    public let dust: Double?
    /// `uv_index`.
    public let uvIndex: Double?
    /// `european_aqi`.
    public let europeanAQI: Double?
    /// `us_aqi`.
    public let usAQI: Double?

    public var id: Date { time }

    public init(time: Date, value: (AirQualityVariable) -> Double?) {
        self.time = time
        pm10 = value(.pm10)
        pm2_5 = value(.pm2_5)
        carbonMonoxide = value(.carbonMonoxide)
        nitrogenDioxide = value(.nitrogenDioxide)
        sulphurDioxide = value(.sulphurDioxide)
        ozone = value(.ozone)
        dust = value(.dust)
        uvIndex = value(.uvIndex)
        europeanAQI = value(.europeanAQI)
        usAQI = value(.usAQI)
    }

    /// The level on the European index, when `european_aqi` was requested.
    public var europeanLevel: AirQualityLevel? {
        europeanAQI.map { AirQualityLevel(europeanAQI: $0) }
    }

    /// The level on the United States index, when `us_aqi` was requested.
    public var usLevel: AirQualityLevel? {
        usAQI.map { AirQualityLevel(usAQI: $0) }
    }
}

extension TimeSeries where Variable == HourlyVariable {
    /// One ``HourlyWeather`` per hour.
    public var rows: [HourlyWeather] {
        times.indices.map { index in
            HourlyWeather(time: times[index]) { value($0, at: index) }
        }
    }

    /// Up to `count` hours starting with the hour that contains `date` (usually the current time).
    public func rows(from date: Date, count: Int) -> [HourlyWeather] {
        let start = index(containing: date) ?? 0
        guard start < times.count, count > 0 else { return [] }
        let end = min(times.count, start + count)
        return (start..<end).map { index in
            HourlyWeather(time: times[index]) { value($0, at: index) }
        }
    }
}

extension TimeSeries where Variable == DailyVariable {
    /// One ``DailyWeather`` per day.
    public var rows: [DailyWeather] {
        times.indices.map { index in
            DailyWeather(
                date: times[index],
                value: { value($0, at: index) },
                timestamp: { timestamp($0, at: index) }
            )
        }
    }
}

extension TimeSeries where Variable == AirQualityVariable {
    /// One ``AirQualityReading`` per hour.
    public var rows: [AirQualityReading] {
        times.indices.map { index in
            AirQualityReading(time: times[index]) { value($0, at: index) }
        }
    }
}

/// The hourly columns of a forecast or a historical response.
public typealias HourlySeries = TimeSeries<HourlyVariable>
/// The daily columns of a forecast or a historical response.
public typealias DailySeries = TimeSeries<DailyVariable>
/// The hourly columns of an air-quality response.
public typealias AirQualitySeries = TimeSeries<AirQualityVariable>
