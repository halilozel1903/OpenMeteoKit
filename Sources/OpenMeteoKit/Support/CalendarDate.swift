import Foundation

/// A day without a time or a time zone, as Open-Meteo writes it: `"2026-10-08"`.
///
/// Used for the `start_date` and `end_date` of the historical API, and to name a day of a daily forecast.
public struct CalendarDate: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Parses `yyyy-MM-dd`. Returns `nil` for anything else.
    public init?(_ string: String) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...12).contains(month), (1...31).contains(day)
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// The day `date` falls on in `timeZone`.
    public init(_ date: Date, in timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year ?? 1970, month: components.month ?? 1, day: components.day ?? 1)
    }

    /// Today in `timeZone`.
    public static func today(in timeZone: TimeZone = .current) -> CalendarDate {
        CalendarDate(Date(), in: timeZone)
    }

    /// The first instant of the day in `timeZone`.
    public func startDate(in timeZone: TimeZone) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// The day `days` days later (or earlier, for a negative number).
    public func adding(days: Int) -> CalendarDate {
        let utc = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let start = startDate(in: utc) else { return self }
        return CalendarDate(start.addingTimeInterval(TimeInterval(days) * 86_400), in: utc)
    }

    /// `yyyy-MM-dd`.
    public var description: String {
        Self.pad(year, 4) + "-" + Self.pad(month, 2) + "-" + Self.pad(day, 2)
    }

    public static func < (lhs: CalendarDate, rhs: CalendarDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = CalendarDate(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected yyyy-MM-dd, got \(string)")
        }
        self = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    private static func pad(_ value: Int, _ width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}
