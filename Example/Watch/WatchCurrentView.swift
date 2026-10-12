import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

/// Now: the place, the temperature and condition, today's high and low, and three small tiles for the feels-like
/// temperature, the wind and the air quality.
struct WatchCurrentView: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        ZStack {
            WatchSky(current: store.current)
            if let forecast = store.forecast, let current = forecast.current {
                ScrollView {
                    VStack(spacing: 10) {
                        CurrentConditionsView(
                            locationName: store.location.name,
                            current: current,
                            today: forecast.today,
                            size: .compact
                        )
                        HStack(spacing: 6) {
                            WatchTile(
                                title: "FEELS",
                                value: WeatherFormat.temperature(current.apparentTemperature),
                                tint: .white
                            )
                            WatchTile(
                                title: current.weather.windCompassDirection?.abbreviation ?? "WIND",
                                value: WeatherFormat.wholeSpeed(current.windSpeed),
                                tint: .white
                            )
                            if let level = store.airQuality?.current?.europeanLevel {
                                WatchTile(title: "AQI", value: String(level.roundedValue), tint: level.color)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                WatchLoadingView()
            }
        }
    }
}

/// A small rounded tile with a caption over a value.
struct WatchTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension WeatherFormat {
    /// A wind speed without its unit, for a tile captioned with the direction.
    static func wholeSpeed(_ value: Double?) -> String {
        guard let value, value.isFinite else { return placeholder }
        return String(Int(value.rounded()))
    }
}
