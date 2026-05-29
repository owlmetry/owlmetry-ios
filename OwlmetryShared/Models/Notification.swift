import Foundation

/// Inbox row from the server. Mirrors `apps/server/src/routes/notifications.ts`
/// `serializeNotification`. The `data` field is intentionally untyped — different
/// notification types embed different shapes; the list view just renders the
/// pre-rendered `title`/`body`, so we don't need to model every variant.
struct OwlmetryNotification: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let type: String
  let title: String
  let body: String?
  let link: String?
  let teamId: String?
  let readAt: String?
  let createdAt: String

  var isUnread: Bool { readAt == nil }
}

struct NotificationsListDTO: Decodable {
  let notifications: [OwlmetryNotification]
  let cursor: String?
  let hasMore: Bool?
}

struct UnreadCountDTO: Decodable {
  let count: Int
}
