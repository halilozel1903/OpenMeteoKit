import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

/// The week: one row per day with its low-to-high bar on a shared scale, and the rain each day brings.
struct WeekScreen: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        ZStack {
            PhoneSky()
            if let forecast = store.forecast {
                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: 2) {
                            Text(store.location.name)
                                .font(.system(size: 32, weight: .medium, design: .rounded))
                            Text(store.location.regionDescription)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        WeatherCard("7-day forecast", systemImage: "calendar") {
                            DailyList(forecast: forecast)
                        }
                        WeatherCard("Precipitation", systemImage: "cloud.rain") {
                            PrecipitationChart(forecast: forecast)
                        }
                        OpenMeteoAttributionView()
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            } else {
                PhoneLoadingView()
            }
        }
    }
}

/// Every day of the forecast; the first reads "Today" and shows the current temperature on its bar.
struct DailyList: View {
    let forecast: Forecast

    var body: some View {
        let days = forecast.dailyWeather
        let scale = TemperatureScale(days: days)
        let today = forecast.today
        VStack(spacing: 0) {
            ForEach(days) { day in
                let isToday = day == today
                DailyForecastRow(
                    day: day,
                    scale: scale,
                    timeZone: forecast.timeZone,
                    title: isToday ? "Today" : nil,
                    currentTemperature: isToday ? forecast.current?.temperature : nil
                )
                .padding(.vertical, 9)
                if day.id != days.last?.id {
                    Divider()
                        .overlay(Color.white.opacity(0.2))
                }
            }
        }
    }
}

/// A bar per day for the precipitation sum, with the chance above it and the weekday below.
struct PrecipitationChart: View {
    let forecast: Forecast

    var body: some View {
        let days = forecast.dailyWeather
        let wettest = max(days.compactMap(\.precipitationSum).max() ?? 0, 1)
        let unit = forecast.daily?.unit(for: .precipitationSum) ?? "mm"
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(days) { day in
                let amount = day.precipitationSum ?? 0
                VStack(spacing: 6) {
                    Text(WeatherFormat.precipitation(amount, unit: "").trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(WeatherPalette.precipitation.opacity(amount > 0 ? 0.9 : 0.25))
                        .frame(height: max(4, 90 * CGFloat(amount / wettest)))
                    Text(WeatherFormat.weekday(day.date, in: forecast.timeZone))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 140, alignment: .bottom)
        Text("Amounts in \(unit). Bars share one scale up to the wettest day.")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.7))
    }
}
