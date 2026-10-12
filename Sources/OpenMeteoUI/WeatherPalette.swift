import OpenMeteoKit
import SwiftUI

/// The colors OpenMeteoUI draws with: sky gradients by condition, temperature colors for range bars and the
/// six air quality categories.
public enum WeatherPalette {
    /// A top-to-bottom sky for a condition, by day or by night.
    public static func sky(for condition: WeatherCondition?, isDay: Bool) -> [Color] {
        guard isDay else {
            switch condition {
            case .clear, .partlyCloudy, nil:
                return [Color(red: 0.05, green: 0.08, blue: 0.22), Color(red: 0.13, green: 0.17, blue: 0.36)]
            case .thunderstorm:
                return [Color(red: 0.08, green: 0.07, blue: 0.16), Color(red: 0.20, green: 0.17, blue: 0.30)]
            default:
                return [Color(red: 0.09, green: 0.11, blue: 0.18), Color(red: 0.20, green: 0.23, blue: 0.31)]
            }
        }
        switch condition {
        case .clear, nil:
            return [Color(red: 0.16, green: 0.45, blue: 0.86), Color(red: 0.42, green: 0.70, blue: 0.96)]
        case .partlyCloudy:
            return [Color(red: 0.22, green: 0.47, blue: 0.80), Color(red: 0.50, green: 0.68, blue: 0.88)]
        case .cloudy, .fog:
            return [Color(red: 0.36, green: 0.43, blue: 0.53), Color(red: 0.58, green: 0.64, blue: 0.72)]
        case .drizzle, .rain, .freezingRain:
            return [Color(red: 0.22, green: 0.30, blue: 0.43), Color(red: 0.39, green: 0.47, blue: 0.59)]
        case .snow:
            return [Color(red: 0.45, green: 0.56, blue: 0.70), Color(red: 0.70, green: 0.78, blue: 0.87)]
        case .thunderstorm:
            return [Color(red: 0.18, green: 0.20, blue: 0.32), Color(red: 0.34, green: 0.33, blue: 0.47)]
        }
    }

    /// A color for a temperature in °C, from deep blue (freezing) through green to red (hot).
    public static func temperature(_ celsius: Double) -> Color {
        switch celsius {
        case ..<0: return Color(red: 0.35, green: 0.55, blue: 1.00)
        case ..<8: return Color(red: 0.30, green: 0.75, blue: 0.98)
        case ..<14: return Color(red: 0.30, green: 0.85, blue: 0.80)
        case ..<19: return Color(red: 0.55, green: 0.88, blue: 0.40)
        case ..<24: return Color(red: 0.98, green: 0.80, blue: 0.25)
        case ..<30: return Color(red: 0.99, green: 0.58, blue: 0.20)
        default: return Color(red: 0.96, green: 0.30, blue: 0.25)
        }
    }

    /// The color of an air quality category, from 0 (good, green) to 5 (worst, purple). Both scales share them.
    public static func airQuality(severity: Int) -> Color {
        let colors = [
            Color(red: 0.31, green: 0.80, blue: 0.47),
            Color(red: 0.82, green: 0.86, blue: 0.27),
            Color(red: 0.99, green: 0.75, blue: 0.20),
            Color(red: 0.98, green: 0.49, blue: 0.20),
            Color(red: 0.91, green: 0.25, blue: 0.29),
            Color(red: 0.61, green: 0.28, blue: 0.70),
        ]
        return colors[min(max(severity, 0), colors.count - 1)]
    }

    /// The color for precipitation chances and amounts.
    public static let precipitation = Color(red: 0.42, green: 0.80, blue: 1.00)
}

extension AirQualityLevel {
    /// The color of the level's category.
    public var color: Color {
        WeatherPalette.airQuality(severity: severity)
    }
}

/// A sky gradient for the current condition, to put behind a screen.
public struct WeatherBackground: View {
    private let condition: WeatherCondition?
    private let isDay: Bool

    public init(condition: WeatherCondition?, isDay: Bool) {
        self.condition = condition
        self.isDay = isDay
    }

    /// The sky for a weather code, by day or by night.
    public init(code: WeatherCode?, isDay: Bool) {
        self.init(condition: code?.condition, isDay: isDay)
    }

    public var body: some View {
        LinearGradient(
            colors: WeatherPalette.sky(for: condition, isDay: isDay),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
