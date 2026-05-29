import Foundation

struct AppUser: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String
  let userId: String
  let isAnonymous: Bool
  let claimedFrom: [String]?
  let lastAppVersion: String?
  let lastCountryCode: String?
  let lastSeenAt: String?
  let firstSeenAt: String
  let properties: [String: String]?
  let apps: [AppUserAppInfo]?
}

struct AppUserAppInfo: Codable, Equatable, Hashable, Identifiable {
  let appId: String
  let appName: String
  let firstSeenAt: String?
  let lastSeenAt: String?

  var id: String { appId }
}

struct UsersListDTO: Decodable {
  let users: [AppUser]
  let cursor: String?
  let hasMore: Bool?
}
