import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

/// Now: the current conditions, the next 24 hours and a grid of details.
struct TodayScreen: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        ZStack {
            PhoneSky()
            if let forecast = store.forecast, let current = forecast.current {
                ScrollView {
                    VStack(spacing: 14) {
                        CurrentConditionsView(locationName: store.location.name, current: current, today: forecast.today)
                            .padding(.top, 24)
                            .padding(.bottom, 12)
                        WeatherCard("Hourly forecast", systemImage: "clock") {
                            Text(hourlySummary(current))
                                .font(.subheadline)
                            HourlyForecastStrip(hours: forecast.upcomingHours(24), timeZone: forecast.timeZone)
                                .padding(.horizontal, -10)
                        }
                        DetailGrid(forecast: forecast, current: current)
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

    private func hourlySummary(_ current: CurrentWeather) -> String {
        let condition = current.weatherCode?.description ?? "Mixed conditions"
        guard let gusts = current.windGusts else { return condition + " now." }
        return condition + " now. Wind gusts up to " + WeatherFormat.speed(gusts, unit: current.unit(for: .windGusts10m) ?? "km/h") + "."
    }
}

/// Two columns of tiles: feels like, humidity, wind, UV index, sunrise, precipitation, pressure and cloud cover.
struct DetailGrid: View {
    let forecast: Forecast
    let current: CurrentWeather

    var body: some View {
        let today = forecast.today
        let zone = forecast.timeZone
        let windUnit = current.unit(for: .windSpeed10m) ?? "km/h"
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            DetailTile(
                title: "Feels like",
                systemImage: "thermometer.medium",
                value: WeatherFormat.temperature(current.apparentTemperature),
                caption: feelsLikeCaption
            )
            DetailTile(
                title: "Humidity",
                systemImage: "humidity",
                value: WeatherFormat.percent(current.relativeHumidity),
                caption: "Cloud cover " + WeatherFormat.percent(current.cloudCover) + "."
            )
            DetailTile(
                title: "Wind",
                systemImage: "wind",
                value: WeatherFormat.wind(speed: current.windSpeed, direction: current.windDirection, unit: windUnit),
                caption: "Gusts " + WeatherFormat.speed(current.windGusts, unit: windUnit) + "."
            )
            DetailTile(
                title: "UV index",
                systemImage: "sun.max",
                value: WeatherFormat.uvIndex(current.uvIndex),
                caption: current.uvIndex.map { WeatherFormat.uvCategory($0) + " now." } ?? ""
            )
            DetailTile(
                title: "Sunrise",
                systemImage: "sunrise",
                value: today?.sunrise.map { WeatherFormat.time($0, in: zone) } ?? WeatherFormat.placeholder,
                caption: today?.sunset.map { "Sunset " + WeatherFormat.time($0, in: zone) + "." } ?? ""
            )
            DetailTile(
                title: "Precipitation",
                systemImage: "drop",
                value: WeatherFormat.precipitation(today?.precipitationSum, unit: forecast.daily?.unit(for: .precipitationSum) ?? "mm"),
                caption: "Today. Chance " + WeatherFormat.percent(today?.precipitationProbabilityMax) + "."
            )
        }
    }

    private var feelsLikeCaption: String {
        guard let actual = current.temperature, let feels = current.apparentTemperature else { return "" }
        if abs(feels - actual) < 1.5 {
            return "Close to the actual temperature."
        }
        return feels < actual ? "Wind makes it feel cooler." : "Humidity makes it feel warmer."
    }
}

/// One detail: a caption with a symbol, a big value and a line of explanation.
struct DetailTile: View {
    let title: String
    let systemImage: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2, reservesSpace: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
