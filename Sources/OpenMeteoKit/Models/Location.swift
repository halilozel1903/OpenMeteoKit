import Foundation

/// A place from the geocoding API (`/v1/search` and `/v1/get`), from the GeoNames database.
public struct Location: Hashable, Sendable, Codable, Identifiable {
    /// The GeoNames id.
    public let id: Int
    /// The place's name in the requested language, such as "Istanbul".
    public let name: String
    public let latitude: Double
    public let longitude: Double
    /// Elevation above sea level, in meters.
    public let elevation: Double?
    /// The GeoNames feature code: `PPLC` for a capital, `PPLA` for a seat of a first-order division,
    /// `PPL` for a populated place, `ADM1` for a first-order administrative division…
    public let featureCode: String?
    /// ISO 3166-1 alpha-2 code, such as "TR".
    public let countryCode: String?
    /// The country's name in the requested language.
    public let country: String?
    /// The GeoNames id of the country.
    public let countryID: Int?
    /// The place's time zone, such as "Europe/Istanbul".
    public let timezone: String?
    public let population: Int?
    public let postcodes: [String]?
    /// First-order administrative division (state, province…).
    public let admin1: String?
    public let admin2: String?
    public let admin3: String?
    public let admin4: String?
    public let admin1ID: Int?
    public let admin2ID: Int?
    public let admin3ID: Int?
    public let admin4ID: Int?

    public init(
        id: Int,
        name: String,
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil,
        featureCode: String? = nil,
        countryCode: String? = nil,
        country: String? = nil,
        countryID: Int? = nil,
        timezone: String? = nil,
        population: Int? = nil,
        postcodes: [String]? = nil,
        admin1: String? = nil,
        admin2: String? = nil,
        admin3: String? = nil,
        admin4: String? = nil,
        admin1ID: Int? = nil,
        admin2ID: Int? = nil,
        admin3ID: Int? = nil,
        admin4ID: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.featureCode = featureCode
        self.countryCode = countryCode
        self.country = country
        self.countryID = countryID
        self.timezone = timezone
        self.population = population
        self.postcodes = postcodes
        self.admin1 = admin1
        self.admin2 = admin2
        self.admin3 = admin3
        self.admin4 = admin4
        self.admin1ID = admin1ID
        self.admin2ID = admin2ID
        self.admin3ID = admin3ID
        self.admin4ID = admin4ID
    }

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, elevation
        case featureCode = "feature_code"
        case countryCode = "country_code"
        case country
        case countryID = "country_id"
        case timezone, population, postcodes
        case admin1, admin2, admin3, admin4
        case admin1ID = "admin1_id"
        case admin2ID = "admin2_id"
        case admin3ID = "admin3_id"
        case admin4ID = "admin4_id"
    }

    /// The coordinate, to request a forecast for.
    public var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }

    /// The region and country, for a second line under the name: "Istanbul, Türkiye", or "Türkiye" when the
    /// region has the place's name.
    public var regionDescription: String {
        var parts: [String] = []
        if let admin1, !admin1.isEmpty, admin1 != name {
            parts.append(admin1)
        }
        if let country, !country.isEmpty {
            parts.append(country)
        } else if let countryCode, !countryCode.isEmpty {
            parts.append(countryCode)
        }
        return parts.joined(separator: ", ")
    }

    /// The place's own time zone, when it has one.
    public var timeZone: TimeZone? {
        timezone.flatMap(TimeZone.init(identifier:))
    }
}

/// `/v1/search` answers `{"results": [...]}`, or no `results` at all when nothing matches.
struct GeocodingResponse: Decodable {
    let results: [Location]?
}
