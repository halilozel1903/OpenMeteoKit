import OpenMeteoKit
import OpenMeteoUI
import SwiftUI

/// Air quality: both indexes as gauges, where they sit on their scales, the particulate matter and the next hours.
struct AirQualityScreen: View {
    @Environment(WeatherStore.self) private var store

    var body: some View {
        ZStack {
            PhoneSky()
            if let air = store.airQuality, let reading = air.current {
                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: 2) {
                            Text(store.location.name)
                                .font(.system(size: 32, weight: .medium, design: .rounded))
                            Text("Air quality")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        if let european = reading.europeanLevel {
                            IndexCard(level: european)
                        }
                        if let us = reading.usLevel {
                            IndexCard(level: us)
                        }
                        WeatherCard("Particulate matter", systemImage: "aqi.low") {
                            PollutantRow(name: "PM2.5", value: reading.pm2_5, unit: air.currentUnits["pm2_5"])
                            PollutantRow(name: "PM10", value: reading.pm10, unit: air.currentUnits["pm10"])
                        }
                        WeatherCard("Next hours", systemImage: "clock") {
                            HourlyIndexChart(readings: upcoming(air), timeZone: air.timeZone)
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

    private func upcoming(_ air: AirQuality) -> [AirQualityReading] {
        guard let hourly = air.hourly, let now = air.current?.time else { return [] }
        let start = hourly.index(containing: now) ?? 0
        return Array(hourly.rows.dropFirst(start).prefix(12))
    }
}

/// One index: its gauge, its category and the bar of all categories.
struct IndexCard: View {
    let level: AirQualityLevel

    var body: some View {
        WeatherCard(level.scale == .european ? "European index" : "US index", systemImage: "aqi.medium") {
            HStack(spacing: 16) {
                AirQualityGauge(level: level)
                    .frame(width: 92, height: 92)
                VStack(alignment: .leading, spacing: 6) {
                    Text(level.title)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(level.color)
                    Text(advice)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            AirQualityScaleBar(level: level)
                .padding(.top, 6)
                .padding(.bottom, 4)
        }
    }

    private var advice: String {
        switch level.severity {
        case 0: return "Air quality is ideal for outdoor activities."
        case 1: return "Enjoy your usual outdoor activities."
        case 2: return "Sensitive people should consider shorter outdoor activities."
        default: return "Consider reducing intense activities outdoors."
        }
    }
}

/// A pollutant with its concentration.
struct PollutantRow: View {
    let name: String
    let value: Double?
    let unit: String?

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Spacer()
            Text(value.map { String(format: "%.1f", $0) } ?? WeatherFormat.placeholder)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .monospacedDigit()
            Text(unit ?? "µg/m³")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

/// A bar per hour for the European index, colored by category.
struct HourlyIndexChart: View {
    let readings: [AirQualityReading]
    let timeZone: TimeZone

    var body: some View {
        let highest = max(readings.compactMap(\.europeanAQI).max() ?? 0, 40)
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(readings) { reading in
                let value = reading.europeanAQI ?? 0
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(reading.europeanLevel?.color ?? Color.gray)
                        .frame(height: max(4, 80 * CGFloat(value / highest)))
                    Text(WeatherFormat.hour(reading.time, in: timeZone))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 110, alignment: .bottom)
    }
}
