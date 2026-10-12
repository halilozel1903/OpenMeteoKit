import Foundation

/// The two air quality indexes Open-Meteo computes.
public enum AirQualityScale: String, CaseIterable, Sendable {
    /// The European Air Quality Index (`european_aqi`): 0–20 good, 20–40 fair, 40–60 moderate, 60–80 poor,
    /// 80–100 very poor, above 100 extremely poor.
    case european
    /// The United States Air Quality Index (`us_aqi`): 0–50 good, 51–100 moderate, 101–150 unhealthy for
    /// sensitive groups, 151–200 unhealthy, 201–300 very unhealthy, 301–500 hazardous.
    case us

    /// "EAQI" or "US AQI".
    public var abbreviation: String {
        switch self {
        case .european: return "EAQI"
        case .us: return "US AQI"
        }
    }
}

/// How healthy the air is, from an index value on one of the ``AirQualityScale``s.
///
/// ```swift
/// let level = AirQualityLevel(europeanAQI: 34)
/// level.title        // "Fair"
/// level.severity     // 1, from 0 (best) to 5 (worst)
/// ```
public struct AirQualityLevel: Hashable, Sendable {
    /// The scale the value is on.
    public let scale: AirQualityScale
    /// The index value.
    public let value: Double
    /// 0 for the best category of the scale to 5 for the worst. Both scales have six categories, so the same
    /// severity can share a color.
    public let severity: Int

    public init(scale: AirQualityScale, value: Double) {
        self.scale = scale
        self.value = value
        let upperBounds: [Double]
        switch scale {
        case .european: upperBounds = [20, 40, 60, 80, 100]
        case .us: upperBounds = [50, 100, 150, 200, 300]
        }
        severity = upperBounds.firstIndex(where: { value <= $0 }) ?? upperBounds.count
    }

    /// A level on the European index.
    public init(europeanAQI value: Double) {
        self.init(scale: .european, value: value)
    }

    /// A level on the United States index.
    public init(usAQI value: Double) {
        self.init(scale: .us, value: value)
    }

    /// The category's name on its scale, such as "Fair" or "Unhealthy for sensitive groups".
    public var title: String {
        switch scale {
        case .european:
            return ["Good", "Fair", "Moderate", "Poor", "Very poor", "Extremely poor"][severity]
        case .us:
            return ["Good", "Moderate", "Unhealthy for sensitive groups", "Unhealthy", "Very unhealthy", "Hazardous"][severity]
        }
    }

    /// A short name that fits a badge: "Sensitive" instead of "Unhealthy for sensitive groups".
    public var shortTitle: String {
        if scale == .us && severity == 2 {
            return "Sensitive"
        }
        return title
    }

    /// Where the value sits on a bar of the scale's six categories drawn at equal widths, from 0 to 1: 0.25 is
    /// halfway through the second category. Values past the top of the scale (100 + 50 on the European index, 500 on
    /// the US index) are clamped to 1.
    public var scalePosition: Double {
        let bounds: [Double]
        switch scale {
        case .european: bounds = [0, 20, 40, 60, 80, 100, 150]
        case .us: bounds = [0, 50, 100, 150, 200, 300, 500]
        }
        guard value.isFinite else { return 0 }
        let lower = bounds[severity]
        let upper = bounds[severity + 1]
        let within = min(max((value - lower) / (upper - lower), 0), 1)
        return (Double(severity) + within) / Double(bounds.count - 1)
    }

    /// The index rounded to a whole number, as it is usually shown.
    public var roundedValue: Int {
        Int(value.rounded())
    }
}
