import Foundation

/// The temperature range of several days, for drawing each day's low-to-high bar on a shared scale, the way a
/// 7-day forecast does.
///
/// ```swift
/// let scale = TemperatureScale(days: forecast.dailyWeather)   // 12.6 ... 23.5 for the Istanbul fixture
/// scale.span(low: 15.8, high: 22.4)                           // 0.29...0.90
/// scale.position(of: 21.9)                                    // 0.85, the "now" dot on today's bar
/// ```
public struct TemperatureScale: Hashable, Sendable {
    /// The lowest temperature of the scale.
    public let lower: Double
    /// The highest temperature of the scale, always above ``lower``.
    public let upper: Double

    /// A scale from `lower` to `upper`. Reversed bounds are swapped, and a scale narrower than one degree is widened
    /// around its middle so bars never divide by zero.
    public init(lower: Double, upper: Double) {
        var low = lower.isFinite ? lower : 0
        var high = upper.isFinite ? upper : 0
        if low > high { swap(&low, &high) }
        if high - low < 1 {
            let middle = (low + high) / 2
            low = middle - 0.5
            high = middle + 0.5
        }
        self.lower = low
        self.upper = high
    }

    /// The scale from the lowest daily minimum to the highest daily maximum of `days`. Days without temperatures are
    /// skipped; with none at all the scale is 0 to 1.
    public init(days: [DailyWeather]) {
        let lows = days.compactMap(\.temperatureMin).filter(\.isFinite)
        let highs = days.compactMap(\.temperatureMax).filter(\.isFinite)
        let all = lows + highs
        self.init(lower: all.min() ?? 0, upper: all.max() ?? 1)
    }

    /// Where `value` is on the scale, from 0 (``lower``) to 1 (``upper``), clamped.
    public func position(of value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max((value - lower) / (upper - lower), 0), 1)
    }

    /// The part of the scale a day covers, from its low to its high, as fractions of the scale.
    public func span(low: Double, high: Double) -> ClosedRange<Double> {
        let start = position(of: min(low, high))
        let end = position(of: max(low, high))
        return start...end
    }
}
