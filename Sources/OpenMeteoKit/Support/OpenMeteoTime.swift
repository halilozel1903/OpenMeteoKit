import Foundation

/// Reads Open-Meteo timestamps.
///
/// With the default `timeformat=iso8601`, times are local to the response's time zone and have no offset:
/// `"2026-10-08T14:00"` for hourly and current values, `"2026-10-08"` for daily values. With
/// `timeformat=unixtime` they are seconds since 1970. Both are turned into `Date`s here.
public enum OpenMeteoTime {
    /// Parses `yyyy-MM-dd'T'HH:mm`, `yyyy-MM-dd'T'HH:mm:ss` or `yyyy-MM-dd` as a local time in `timeZone`.
    public static func date(from string: String, in timeZone: TimeZone) -> Date? {
        let halves = string.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: false)
        guard let day = CalendarDate(String(halves[0])) else { return nil }
        var hour = 0
        var minute = 0
        var second = 0
        if halves.count == 2 {
            let clock = halves[1].split(separator: ":", omittingEmptySubsequences: false)
            guard clock.count == 2 || clock.count == 3,
                  let h = Int(clock[0]), let m = Int(clock[1]),
                  (0...23).contains(h), (0...59).contains(m)
            else { return nil }
            hour = h
            minute = m
            if clock.count == 3 {
                guard let s = Int(clock[2]), (0...60).contains(s) else { return nil }
                second = s
            }
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(
            year: day.year, month: day.month, day: day.day,
            hour: hour, minute: minute, second: second
        ))
    }
}

/// A timestamp as it appears in a response: a local ISO 8601 string or Unix seconds.
enum RawTime: Decodable, Hashable, Sendable {
    case text(String)
    case unix(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else {
            self = .unix(try container.decode(Double.self))
        }
    }

    func date(in timeZone: TimeZone) -> Date? {
        switch self {
        case let .text(text):
            return OpenMeteoTime.date(from: text, in: timeZone)
        case let .unix(seconds):
            return Date(timeIntervalSince1970: seconds)
        }
    }
}

/// A coding key for JSON objects whose keys are only known at run time (one per requested variable).
struct AnyCodingKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?

    init(_ string: String) {
        stringValue = string
        intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}
