import Foundation

struct AppModel: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let teamId: String
  let projectId: String
  let name: String
  let platform: AppPlatform
  let bundleId: String?
  let latestAppVersion: String?
  let latestAppVersionUpdatedAt: String?
  let latestAppVersionSource: String?
  let appleAppStoreId: Int?
  // Worldwide rating cache populated daily by app_store_ratings_sync from a
  // weighted average over per-country snapshots in app_store_ratings.
  let worldwideAverageRating: Double?
  let worldwideRatingCount: Int?
  let worldwideCurrentVersionRating: Double?
  let worldwideCurrentVersionRatingCount: Int?
  let ratingsSyncedAt: String?
  let createdAt: String
  let updatedAt: String?
}

struct AppsListDTO: Decodable {
  let apps: [AppModel]
}
