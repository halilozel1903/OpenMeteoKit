import Foundation

/// The credit Open-Meteo asks for. Open-Meteo's data is licensed under
/// [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/): show the credit with a link back wherever the
/// data appears.
public enum OpenMeteoAttribution {
    /// "Weather data by Open-Meteo.com".
    public static let text = "Weather data by Open-Meteo.com"
    /// https://open-meteo.com
    public static let url = URL(string: "https://open-meteo.com")!
    /// The data license, CC BY 4.0.
    public static let licenseName = "CC BY 4.0"
    /// https://creativecommons.org/licenses/by/4.0/
    public static let licenseURL = URL(string: "https://creativecommons.org/licenses/by/4.0/")!
}
