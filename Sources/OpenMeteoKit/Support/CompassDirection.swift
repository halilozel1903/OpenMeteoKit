import Foundation

/// One of the 16 points of the compass, for a wind direction in degrees.
///
/// Open-Meteo's `wind_direction_10m` is the direction the wind comes **from**, in degrees clockwise from north:
/// 0 is a north wind, 90 an east wind.
public enum CompassDirection: String, CaseIterable, Sendable {
    case n = "N", nne = "NNE", ne = "NE", ene = "ENE"
    case e = "E", ese = "ESE", se = "SE", sse = "SSE"
    case s = "S", ssw = "SSW", sw = "SW", wsw = "WSW"
    case w = "W", wnw = "WNW", nw = "NW", nnw = "NNW"

    /// The nearest point for `degrees`; any angle works, including negative ones and ones past 360.
    public init(degrees: Double) {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let index = Int((normalized / 22.5).rounded()) % 16
        self = CompassDirection.allCases[index]
    }

    /// The abbreviation, such as "NE".
    public var abbreviation: String { rawValue }

    /// The point's center in degrees.
    public var degrees: Double {
        Double(CompassDirection.allCases.firstIndex(of: self) ?? 0) * 22.5
    }
}
