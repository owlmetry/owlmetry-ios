import Foundation

// Per-country App Store rating aggregates (incl. star-only ratings, not just
// text reviews). Populated daily by the server's app_store_ratings_sync job
// from iTunes Lookup fan-out across every Apple storefront.

struct RatingsByCountrySummary: Codable, Identifiable, Equatable, Hashable {
  let countryCode: String
  let ratingCount: Int
  // Change since the previous daily snapshot. Null on first-day data.
  let ratingCountDelta: Int?
  let averageRating: Double

  var id: String { countryCode }
}

struct RatingsByCountryDTO: Decodable {
  let countries: [RatingsByCountrySummary]
}

struct PerCountryRating: Codable, Identifiable, Equatable, Hashable {
  let countryCode: String
  let averageRating: Double?
  let ratingCount: Int
  let ratingCountDelta: Int?
  let currentVersionAverageRating: Double?
  let currentVersionRatingCount: Int?
  let appVersion: String?
  let snapshotDate: String

  var id: String { countryCode }
}

struct AppRatingSummary: Codable, Equatable, Hashable {
  let worldwideAverage: Double?
  let worldwideCount: Int
  // Sum of per-country deltas; null if no country has prior data for this app.
  let worldwideRatingCountDelta: Int?
  let currentVersionAverage: Double?
  let currentVersionCount: Int?
  let syncedAt: String?
}

struct AppRatingsDTO: Decodable {
  let ratings: [PerCountryRating]
  let summary: AppRatingSummary
}
