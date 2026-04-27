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
  let latestRating: Double?
  let latestRatingCount: Int?
  let currentVersionRating: Double?
  let currentVersionRatingCount: Int?
  let appleAppStoreId: Int?
  let createdAt: String
  let updatedAt: String?
}

struct AppsListDTO: Decodable {
  let apps: [AppModel]
}
