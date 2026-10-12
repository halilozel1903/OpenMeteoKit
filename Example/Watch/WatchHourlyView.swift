import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

/// The next hours as a list: the hour, the condition, the chance of rain and the temperature.
struct WatchHourlyView: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        ZStack {
            WatchSky(current: store.current)
            if let forecast = store.forecast {
                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Next hours")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.leading, 2)
                        ForEach(Array(forecast.upcomingHours(12).enumerated()), id: \.element.id) { index, hour in
                            HourlyForecastRow(
                                hour: hour,
                                label: index == 0 ? "Now" : WeatherFormat.hour(hour.time, in: forecast.timeZone)
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                WatchLoadingView()
            }
        }
    }
}

/// The week: one row per day with its condition and its high and low.
struct WatchWeekView: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        ZStack {
            WatchSky(current: store.current)
            if let forecast = store.forecast {
                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("7 days")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.leading, 2)
                        ForEach(Array(forecast.dailyWeather.enumerated()), id: \.element.id) { index, day in
                            HStack(spacing: 6) {
                                Text(index == 0 ? "Today" : WeatherFormat.weekday(day.date, in: forecast.timeZone))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .frame(width: 52, alignment: .leading)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                WeatherSymbol(day.weatherCode)
                                    .font(.system(size: 18))
                                    .frame(width: 28)
                                Spacer(minLength: 0)
                                Text(WeatherFormat.temperature(day.temperatureMin))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(WeatherFormat.temperature(day.temperatureMax))
                            }
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        OpenMeteoAttributionView()
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                WatchLoadingView()
            }
        }
    }
}
