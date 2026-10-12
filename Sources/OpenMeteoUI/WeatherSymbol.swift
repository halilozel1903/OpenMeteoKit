import OpenMeteoKit
import SwiftUI

/// The SF Symbol of a WMO weather code in multicolor, by day or by night, with the condition as its
/// accessibility label.
///
/// ```swift
/// WeatherSymbol(current.weatherCode, isDay: current.isDay)
///     .font(.system(size: 44))
/// ```
public struct WeatherSymbol: View {
    private let code: WeatherCode?
    private let isDay: Bool

    public init(_ code: WeatherCode?, isDay: Bool = true) {
        self.code = code
        self.isDay = isDay
    }

    public var body: some View {
        Image(systemName: code?.symbolName(isDay: isDay) ?? "questionmark.circle")
            .symbolRenderingMode(.multicolor)
            .accessibilityLabel(code?.description ?? "Unknown conditions")
    }
}

/// The credit Open-Meteo's CC BY 4.0 license asks for: "Weather data by Open-Meteo.com", linking to
/// open-meteo.com.
public struct OpenMeteoAttributionView: View {
    public init() {}

    public var body: some View {
        Link(destination: OpenMeteoAttribution.url) {
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                Text(OpenMeteoAttribution.text)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}
