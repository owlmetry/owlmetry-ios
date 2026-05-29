import Foundation

enum EventsService {
  static func count(
    teamId: String,
    projectId: String?,
    since: String,
    dataMode: DataMode
  ) async throws -> EventsCountResponse {
    try await APIClient.shared.get(
      "/v1/events/count",
      query: [
        "team_id": teamId,
        "project_id": projectId,
        "since": since,
        "data_mode": dataMode.rawValue
      ]
    )
  }

  static func list(
    teamId: String,
    projectId: String?,
    appId: String? = nil,
    sessionId: String? = nil,
    userId: String? = nil,
    dataMode: DataMode,
    cursor: String? = nil,
    limit: Int = 50
  ) async throws -> EventsListDTO {
    try await APIClient.shared.get(
      "/v1/events",
      query: [
        "team_id": teamId,
        "project_id": projectId,
        "app_id": appId,
        "session_id": sessionId,
        "user_id": userId,
        "data_mode": dataMode.rawValue,
        "cursor": cursor,
        "limit": String(limit)
      ]
    )
  }
}
