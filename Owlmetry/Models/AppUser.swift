import Foundation

struct AppUser: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String
  let userId: String
  let isAnonymous: Bool
  let claimedFrom: String?
  let lastAppVersion: String?
  let lastCountryCode: String?
  let lastSeenAt: String?
  let firstSeenAt: String
  let properties: [String: String]?
  let apps: [AppUserAppInfo]?
  let createdAt: String
  let updatedAt: String
}

struct AppUserAppInfo: Codable, Equatable, Hashable {
  let id: String
  let name: String
  let projectId: String?
  let platform: AppPlatform?
  let bundleId: String?
  let lastSeenAt: String?
}

struct UsersListDTO: Decodable {
  let users: [AppUser]
  let cursor: String?
  let hasMore: Bool?
}
