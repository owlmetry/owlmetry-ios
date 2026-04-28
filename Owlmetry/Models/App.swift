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
  // Null when the app has no prior snapshot data.
  let worldwideRatingCountDelta: Int?
  let worldwideCurrentVersionRating: Double?
  let worldwideCurrentVersionRatingCount: Int?
  let ratingsSyncedAt: String?
  let createdAt: String
  let updatedAt: String?
}

struct AppsListDTO: Decodable {
  let apps: [AppModel]
}

// Weighted-average rating + total + delta across a set of apps. Each app's
// worldwide cache is itself a daily weighted aggregate; weighting again here
// by per-app rating count prevents a 5★ app with 1 rating from outweighing a
// 4★ app with 50,000. Delta is nil when no app has a previous-snapshot
// baseline (first-day data).
func ratingSummary(for apps: [AppModel]) -> (avg: Double, total: Int, delta: Int?)? {
  var weightedSum: Double = 0
  var total: Int = 0
  var delta: Int = 0
  var hasDelta = false
  for app in apps {
    guard let rating = app.worldwideAverageRating, let count = app.worldwideRatingCount, count > 0 else { continue }
    weightedSum += rating * Double(count)
    total += count
    if let d = app.worldwideRatingCountDelta {
      delta += d
      hasDelta = true
    }
  }
  guard total > 0 else { return nil }
  return (weightedSum / Double(total), total, hasDelta ? delta : nil)
}
