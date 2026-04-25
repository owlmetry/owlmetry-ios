import Foundation

enum NotificationsService {
  static func list(
    readState: String? = nil,
    type: String? = nil,
    cursor: String? = nil,
    limit: Int = 50
  ) async throws -> NotificationsListDTO {
    try await APIClient.shared.get(
      "/v1/notifications",
      query: [
        "read_state": readState,
        "type": type,
        "cursor": cursor,
        "limit": String(limit),
      ]
    )
  }

  static func unreadCount() async throws -> UnreadCountDTO {
    try await APIClient.shared.get("/v1/notifications/unread-count")
  }

  static func markRead(id: String) async throws {
    struct Body: Encodable { let read: Bool }
    struct Empty: Decodable {}
    let _: Empty = try await APIClient.shared.patch(
      "/v1/notifications/\(id)",
      body: Body(read: true)
    )
  }

  static func markAllRead(type: String? = nil) async throws -> Int {
    struct Body: Encodable { let type: String? }
    struct Response: Decodable { let marked: Int }
    let res: Response = try await APIClient.shared.post(
      "/v1/notifications/mark-all-read",
      body: Body(type: type)
    )
    return res.marked
  }

  static func delete(id: String) async throws {
    struct Empty: Decodable {}
    let _: Empty = try await APIClient.shared.delete("/v1/notifications/\(id)")
  }
}
