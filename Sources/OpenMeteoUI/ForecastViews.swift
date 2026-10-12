import OpenMeteoKit
import SwiftUI

// MARK: - Current conditions

/// The current conditions as a weather app's header: the place, a big temperature, the condition and today's
/// high and low.
///
/// ```swift
/// CurrentConditionsView(locationName: "Istanbul", current: current, today: forecast.today)
/// ```
public struct CurrentConditionsView: View {
    /// How much room the header has.
    public enum Size: Sendable {
        /// The top of an iPhone screen.
        case large
        /// An Apple Watch screen.
        case compact
    }

    private let locationName: String
    private let current: CurrentWeather
    private let today: DailyWeather?
    private let size: Size

    public init(locationName: String, current: CurrentWeather, today: DailyWeather?, size: Size = .large) {
        self.locationName = locationName
        self.current = current
        self.today = today
        self.size = size
    }

    public var body: some View {
        VStack(spacing: size == .large ? 2 : 0) {
            Text(locationName)
                .font(.system(size: size == .large ? 32 : 17, weight: size == .large ? .medium : .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(alignment: .center, spacing: size == .large ? 10 : 6) {
                WeatherSymbol(current.weatherCode, isDay: current.isDay)
                    .font(.system(size: size == .large ? 44 : 30))
                Text(WeatherFormat.temperature(current.temperature))
                    .font(.system(size: size == .large ? 92 : 50, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text(current.weatherCode?.summary(isDay: current.isDay) ?? WeatherFormat.placeholder)
                .font(.system(size: size == .large ? 20 : 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let today {
                Text("H:\(WeatherFormat.temperature(today.temperatureMax))  L:\(WeatherFormat.temperature(today.temperatureMin))")
                    .font(.system(size: size == .large ? 20 : 14, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Hourly

/// A horizontal strip of the coming hours: the hour, the condition, the chance of precipitation when it is
/// worth showing, and the temperature. The first hour reads "Now".
///
/// ```swift
/// HourlyForecastStrip(hours: forecast.upcomingHours(24), timeZone: forecast.timeZone)
/// ```
public struct HourlyForecastStrip: View {
    private let hours: [HourlyWeather]
    private let timeZone: TimeZone
    private let locale: Locale

    public init(hours: [HourlyWeather], timeZone: TimeZone, locale: Locale = .current) {
        self.hours = hours
        self.timeZone = timeZone
        self.locale = locale
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                    HourlyForecastCell(
                        hour: hour,
                        label: index == 0 ? "Now" : WeatherFormat.hour(hour.time, in: timeZone, locale: locale)
                    )
                }
            }
            .padding(.horizontal, 10)
        }
        .scrollIndicators(.hidden)
    }
}

/// One hour of ``HourlyForecastStrip``.
public struct HourlyForecastCell: View {
    private let hour: HourlyWeather
    private let label: String

    public init(hour: HourlyWeather, label: String) {
        self.hour = hour
        self.label = label
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(1)
            VStack(spacing: 2) {
                WeatherSymbol(hour.weatherCode, isDay: hour.isDay ?? true)
                    .font(.system(size: 22))
                    .frame(height: 26)
                Text(PrecipitationChance.label(hour.precipitationProbability) ?? " ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(WeatherPalette.precipitation)
            }
            Text(WeatherFormat.temperature(hour.temperature))
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .frame(minWidth: 50)
        .accessibilityElement(children: .combine)
    }
}

/// One hour as a list row, for narrow screens such as Apple Watch: the hour, the condition, the chance of
/// precipitation and the temperature.
public struct HourlyForecastRow: View {
    private let hour: HourlyWeather
    private let label: String

    public init(hour: HourlyWeather, label: String) {
        self.hour = hour
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(width: 54, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            WeatherSymbol(hour.weatherCode, isDay: hour.isDay ?? true)
                .font(.system(size: 18))
                .frame(width: 28)
            Text(PrecipitationChance.label(hour.precipitationProbability) ?? "")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(WeatherPalette.precipitation)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(WeatherFormat.temperature(hour.temperature))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

/// When a chance of precipitation is worth a label in a forecast: 20% and up, rounded to tens like most weather
/// apps.
enum PrecipitationChance {
    static func label(_ probability: Double?) -> String? {
        guard let probability, probability.isFinite, probability >= 20 else { return nil }
        let rounded = Int((probability / 10).rounded()) * 10
        return "\(min(rounded, 100))%"
    }
}

// MARK: - Daily

/// One day of a multi-day forecast: the weekday, the condition, the chance of precipitation, and a bar from the
/// low to the high on a scale shared by every day of the list. Today's bar can show the current temperature.
///
/// ```swift
/// let scale = TemperatureScale(days: forecast.dailyWeather)
/// ForEach(forecast.dailyWeather) { day in
///     DailyForecastRow(day: day, scale: scale, timeZone: forecast.timeZone)
/// }
/// ```
public struct DailyForecastRow: View {
    private let day: DailyWeather
    private let scale: TemperatureScale
    private let title: String
    private let currentTemperature: Double?

    /// - Parameters:
    ///   - title: The weekday by default; pass "Today" for the first day.
    ///   - currentTemperature: Draws a dot on the bar, for today.
    public init(
        day: DailyWeather,
        scale: TemperatureScale,
        timeZone: TimeZone,
        title: String? = nil,
        currentTemperature: Double? = nil,
        locale: Locale = .current
    ) {
        self.day = day
        self.scale = scale
        self.title = title ?? WeatherFormat.weekday(day.date, in: timeZone, locale: locale)
        self.currentTemperature = currentTemperature
    }

    public var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .frame(width: 62, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            VStack(spacing: 0) {
                WeatherSymbol(day.weatherCode)
                    .font(.system(size: 20))
                    .frame(height: 24)
                if let chance = PrecipitationChance.label(day.precipitationProbabilityMax) {
                    Text(chance)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(WeatherPalette.precipitation)
                }
            }
            .frame(width: 36)
            Text(WeatherFormat.temperature(day.temperatureMin))
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .trailing)
            TemperatureRangeBar(
                low: day.temperatureMin,
                high: day.temperatureMax,
                scale: scale,
                current: currentTemperature
            )
            Text(WeatherFormat.temperature(day.temperatureMax))
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A capsule from a day's low to its high on a shared ``TemperatureScale``, colored from cool to warm, with an
/// optional dot for the current temperature.
public struct TemperatureRangeBar: View {
    private let low: Double?
    private let high: Double?
    private let scale: TemperatureScale
    private let current: Double?

    public init(low: Double?, high: Double?, scale: TemperatureScale, current: Double? = nil) {
        self.low = low
        self.high = high
        self.scale = scale
        self.current = current
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.14))
                if let low, let high {
                    let span = scale.span(low: low, high: high)
                    let barWidth = max(height, width * CGFloat(span.upperBound - span.lowerBound))
                    let start = min(width * CGFloat(span.lowerBound), width - barWidth)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [WeatherPalette.temperature(min(low, high)), WeatherPalette.temperature(max(low, high))],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: barWidth)
                        .offset(x: start)
                }
                if let current {
                    let dot = height + 3
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1.5))
                        .frame(width: dot, height: dot)
                        .offset(x: min(max(width * CGFloat(scale.position(of: current)) - dot / 2, 0), width - dot))
                }
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}

// MARK: - Air quality

/// A ring gauge for an air quality index, colored by category, with the value and the category's short name.
///
/// ```swift
/// if let level = airQuality.current?.europeanLevel {
///     AirQualityGauge(level: level)
/// }
/// ```
public struct AirQualityGauge: View {
    private let level: AirQualityLevel
    private let lineWidth: CGFloat

    public init(level: AirQualityLevel, lineWidth: CGFloat = 10) {
        self.level = level
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.primary.opacity(0.14), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: CGFloat(0.75 * max(0.02, level.scalePosition)))
                .stroke(level.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
            VStack(spacing: 0) {
                Text(String(level.roundedValue))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                Text(level.scale.abbreviation)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(lineWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(level.scale.abbreviation) \(level.roundedValue), \(level.title)")
    }
}

/// The six categories of an air quality scale as one bar, with a marker at the current value.
public struct AirQualityScaleBar: View {
    private let level: AirQualityLevel

    public init(level: AirQualityLevel) {
        self.level = level
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack(alignment: .leading) {
                HStack(spacing: 2) {
                    ForEach(0..<6, id: \.self) { severity in
                        Rectangle()
                            .fill(WeatherPalette.airQuality(severity: severity))
                    }
                }
                .clipShape(Capsule())
                let marker = height + 6
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 2))
                    .frame(width: marker, height: marker)
                    .offset(x: min(max(width * CGFloat(level.scalePosition) - marker / 2, 0), width - marker))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
