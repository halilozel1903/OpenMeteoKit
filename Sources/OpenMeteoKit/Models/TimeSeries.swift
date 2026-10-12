import Foundation

/// One block of Open-Meteo's columnar data, such as `hourly` or `daily`.
///
/// Open-Meteo sends one array per variable, all as long as `time`:
///
/// ```json
/// "hourly": {
///   "time": ["2026-10-08T00:00", "2026-10-08T01:00", …],
///   "temperature_2m": [16.4, 16.0, …],
///   "weather_code": [1, 1, …]
/// }
/// ```
///
/// A `TimeSeries` keeps those columns, with the times parsed into `Date`s, and turns them into rows:
/// ``rows`` gives ``HourlyWeather``, ``DailyWeather`` or ``AirQualityReading`` values, one per time.
/// Columns can also be read directly with a subscript (`series[.temperature2m]`). Values Open-Meteo has no data
/// for are `null` in the JSON and `nil` here.
public struct TimeSeries<Variable: OpenMeteoVariable>: Hashable, Sendable {
    /// The time of each row.
    public let times: [Date]
    /// The unit of each variable, by API name, from the `*_units` object (for example `"°C"`).
    public let units: [String: String]
    /// Numeric columns by API name, including variables this package has no case for.
    public let columns: [String: [Double?]]
    /// Timestamp columns (`sunrise`, `sunset`) by API name.
    public let timestampColumns: [String: [Date?]]

    public init(
        times: [Date],
        units: [String: String] = [:],
        columns: [String: [Double?]] = [:],
        timestampColumns: [String: [Date?]] = [:]
    ) {
        self.times = times
        self.units = units
        self.columns = columns
        self.timestampColumns = timestampColumns
    }

    /// The number of rows.
    public var count: Int { times.count }

    /// `true` when there are no rows.
    public var isEmpty: Bool { times.isEmpty }

    /// The variables the response has a column for, in the enum's order.
    public var variables: [Variable] {
        Variable.allCases.filter { columns[$0.rawValue] != nil || timestampColumns[$0.rawValue] != nil }
    }

    /// The numeric column of `variable`, or an empty array when the response has none.
    public subscript(variable: Variable) -> [Double?] {
        columns[variable.rawValue] ?? []
    }

    /// The numeric column with an API name this package has no case for, such as `"cape"`.
    public subscript(name: String) -> [Double?] {
        columns[name] ?? []
    }

    /// The timestamps of `variable` (`sunrise`, `sunset`), or an empty array when the response has none.
    public func timestamps(_ variable: Variable) -> [Date?] {
        timestampColumns[variable.rawValue] ?? []
    }

    /// The unit of `variable`, such as `"°C"` or `"km/h"`.
    public func unit(for variable: Variable) -> String? {
        units[variable.rawValue]
    }

    /// The value of `variable` in row `index`, or `nil` when it is missing.
    public func value(_ variable: Variable, at index: Int) -> Double? {
        guard let column = columns[variable.rawValue], column.indices.contains(index) else { return nil }
        return column[index]
    }

    /// The timestamp of `variable` in row `index`, or `nil` when it is missing.
    public func timestamp(_ variable: Variable, at index: Int) -> Date? {
        guard let column = timestampColumns[variable.rawValue], column.indices.contains(index) else { return nil }
        return column[index]
    }

    /// The index of the row for the hour (or day) that contains `date`: the last row at or before it.
    public func index(containing date: Date) -> Int? {
        guard let first = times.first, date >= first else { return nil }
        var low = 0
        var high = times.count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if times[middle] <= date {
                low = middle
            } else {
                high = middle - 1
            }
        }
        return low
    }

    /// Builds a series from a decoded block, parsing times in `timeZone`.
    init(raw: RawColumns, units: [String: String], timeZone: TimeZone) throws {
        var times: [Date] = []
        times.reserveCapacity(raw.time.count)
        for (index, time) in raw.time.enumerated() {
            guard let date = time.date(in: timeZone) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [AnyCodingKey("time"), AnyCodingKey(intValue: index) ?? AnyCodingKey("\(index)")],
                    debugDescription: "Unreadable time \(time)"
                ))
            }
            times.append(date)
        }
        var columns: [String: [Double?]] = [:]
        var timestamps: [String: [Date?]] = [:]
        for (name, values) in raw.numbers {
            if Variable(rawValue: name)?.isTimestamp == true {
                // timeformat=unixtime: sunrise and sunset are numbers.
                timestamps[name] = values.map { $0.map { Date(timeIntervalSince1970: $0) } }
            } else {
                columns[name] = values
            }
        }
        for (name, values) in raw.texts {
            timestamps[name] = values.map { $0.flatMap { OpenMeteoTime.date(from: $0, in: timeZone) } }
        }
        self.init(times: times, units: units, columns: columns, timestampColumns: timestamps)
    }
}

/// A columnar block as it is in the JSON, before times are parsed.
struct RawColumns: Decodable {
    var time: [RawTime] = []
    var numbers: [String: [Double?]] = [:]
    var texts: [String: [String?]] = [:]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        for key in container.allKeys {
            if key.stringValue == "time" {
                time = try container.decode([RawTime].self, forKey: key)
            } else if let numbers = try? container.decode([Double?].self, forKey: key) {
                self.numbers[key.stringValue] = numbers
            } else if let texts = try? container.decode([String?].self, forKey: key) {
                self.texts[key.stringValue] = texts
            }
            // Anything else is not a column; it is skipped.
        }
    }
}

/// A block of current values (`current`) as it is in the JSON, before the time is parsed.
struct RawSnapshot: Decodable {
    var time: RawTime?
    var interval: Int?
    var numbers: [String: Double] = [:]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        for key in container.allKeys {
            switch key.stringValue {
            case "time":
                time = try container.decode(RawTime.self, forKey: key)
            case "interval":
                interval = try? container.decode(Int.self, forKey: key)
            default:
                if let number = try? container.decodeIfPresent(Double.self, forKey: key) {
                    numbers[key.stringValue] = number
                }
            }
        }
    }

    func date(in timeZone: TimeZone, codingPath: [any CodingKey]) throws -> Date {
        guard let date = time?.date(in: timeZone) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Missing or unreadable current time"
            ))
        }
        return date
    }
}
