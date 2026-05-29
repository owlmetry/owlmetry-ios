import Foundation

struct StoredEvent: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String?
  let appId: String?
  let userId: String?
  let sessionId: String?
  let timestamp: String
  let level: String?
  let environment: String?
  let appVersion: String?
  let screenName: String?
  let stepName: String?
  let message: String?
  let countryCode: String?
  let isDev: Bool?
  let customAttributes: [String: String]?
}

struct EventsListDTO: Decodable {
  let events: [StoredEvent]
  let cursor: String?
  let hasMore: Bool?
}
