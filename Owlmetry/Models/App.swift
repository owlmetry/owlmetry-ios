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
  let createdAt: String
  let updatedAt: String?
}

struct AppsListDTO: Decodable {
  let apps: [AppModel]
}
