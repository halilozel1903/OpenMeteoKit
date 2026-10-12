import Foundation

/// Short texts for weather values, as a weather app shows them.
///
/// Numbers are formatted without the user's locale (always a `.` separator) so they read the same everywhere and in
/// tests; hours and weekdays use the locale you pass.
///
/// ```swift
/// WeatherFormat.temperature(21.6)                       // "22°"
/// WeatherFormat.temperature(21.6, unit: .celsius)       // "22 °C"
/// WeatherFormat.percent(59)                             // "59%"
/// WeatherFormat.speed(14.8, unit: "km/h")               // "15 km/h"
/// WeatherFormat.precipitation(4.26, unit: "mm")         // "4.3 mm"
/// WeatherFormat.uvCategory(3.45)                        // "Moderate"
/// ```
public enum WeatherFormat {
    /// The text for a missing value.
    public static let placeholder = "--"

    /// A whole-degree temperature with a degree sign, such as "22°" or "-3°". Never "-0°".
    public static func temperature(_ value: Double?) -> String {
        guard let degrees = wholeNumber(value) else { return placeholder }
        return "\(degrees)°"
    }

    /// A whole-degree temperature with its unit, such as "22 °C" or "72 °F".
    public static func temperature(_ value: Double?, unit: TemperatureUnit) -> String {
        guard let degrees = wholeNumber(value) else { return placeholder }
        return "\(degrees) \(unit.symbol)"
    }

    /// A rounded percentage, such as "59%".
    public static func percent(_ value: Double?) -> String {
        guard let percent = wholeNumber(value) else { return placeholder }
        return "\(percent)%"
    }

    /// A rounded speed with its unit, such as "15 km/h".
    public static func speed(_ value: Double?, unit: String) -> String {
        guard let speed = wholeNumber(value) else { return placeholder }
        return "\(speed) \(unit)"
    }

    /// An amount of precipitation: one decimal below 10 ("0.4 mm", "4.3 mm"), whole numbers above ("12 mm"), and
    /// "0 mm" for none.
    public static func precipitation(_ value: Double?, unit: String) -> String {
        guard let value, value.isFinite else { return placeholder }
        let amount = max(0, value)
        if amount == 0 {
            return "0 \(unit)"
        }
        if amount < 9.95 {
            var text = String(format: "%.1f", amount)
            if text.hasSuffix(".0") { text.removeLast(2) }
            return text + " " + unit
        }
        return "\(Int(amount.rounded())) \(unit)"
    }

    /// A rounded UV index, such as "3".
    public static func uvIndex(_ value: Double?) -> String {
        guard let index = wholeNumber(value) else { return placeholder }
        return String(max(0, index))
    }

    /// The WHO category of a UV index: Low (0–2), Moderate (3–5), High (6–7), Very high (8–10) or Extreme (11+).
    public static func uvCategory(_ value: Double) -> String {
        guard value.isFinite else { return placeholder }
        switch Int(max(0, value).rounded()) {
        case ..<3: return "Low"
        case 3...5: return "Moderate"
        case 6...7: return "High"
        case 8...10: return "Very high"
        default: return "Extreme"
        }
    }

    /// A wind with its direction, such as "15 km/h NE".
    public static func wind(speed: Double?, direction: Double?, unit: String) -> String {
        let text = self.speed(speed, unit: unit)
        guard speed != nil, let direction, direction.isFinite else { return text }
        return text + " " + CompassDirection(degrees: direction).abbreviation
    }

    /// A visibility in kilometers from meters, such as "24 km" or "0.8 km".
    public static func visibility(meters: Double?) -> String {
        guard let meters, meters.isFinite else { return placeholder }
        let kilometers = max(0, meters) / 1_000
        if kilometers < 9.95 {
            var text = String(format: "%.1f", kilometers)
            if text.hasSuffix(".0") { text.removeLast(2) }
            return text + " km"
        }
        return "\(Int(kilometers.rounded())) km"
    }

    /// The hour of `date` in `timeZone` the way `locale` writes it: "2 PM" in English, "14" in Turkish.
    public static func hour(_ date: Date, in timeZone: TimeZone, locale: Locale = .current) -> String {
        formatted(date, template: "j", timeZone: timeZone, locale: locale)
    }

    /// The time of `date` in `timeZone`, such as "7:10 AM" or "07:10".
    public static func time(_ date: Date, in timeZone: TimeZone, locale: Locale = .current) -> String {
        formatted(date, template: "jmm", timeZone: timeZone, locale: locale)
    }

    /// The abbreviated weekday of `date` in `timeZone`, such as "Thu".
    public static func weekday(_ date: Date, in timeZone: TimeZone, locale: Locale = .current) -> String {
        formatted(date, template: "EEE", timeZone: timeZone, locale: locale)
    }

    /// The full weekday of `date` in `timeZone`, such as "Thursday".
    public static func fullWeekday(_ date: Date, in timeZone: TimeZone, locale: Locale = .current) -> String {
        formatted(date, template: "EEEE", timeZone: timeZone, locale: locale)
    }

    /// A duration in hours and minutes, such as "11 h 32 min", for daylight and sunshine durations.
    public static func duration(seconds: Double?) -> String {
        guard let seconds, seconds.isFinite else { return placeholder }
        let minutes = Int((max(0, seconds) / 60).rounded())
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }

    // MARK: - Helpers

    /// The value rounded to a whole number, `nil` when it is missing or not finite. `-0.4` gives `0`.
    static func wholeNumber(_ value: Double?) -> Int? {
        guard let value, value.isFinite, abs(value) < 1e9 else { return nil }
        let rounded = Int(value.rounded())
        return rounded == 0 ? 0 : rounded
    }

    private static func formatted(_ date: Date, template: String, timeZone: TimeZone, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}
