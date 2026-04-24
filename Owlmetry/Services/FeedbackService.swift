import Foundation

enum FeedbackService {
  static func list(
    teamId: String,
    projectId: String?,
    dataMode: DataMode,
    status: FeedbackStatus? = nil,
    appId: String? = nil,
    isDev: Bool? = nil,
    cursor: String? = nil,
    limit: Int = 50
  ) async throws -> FeedbackListDTO {
    if let projectId {
      return try await APIClient.shared.get(
        "/v1/projects/\(projectId)/feedback",
        query: [
          "status": status?.rawValue,
          "app_id": appId,
          "is_dev": isDev.map { $0 ? "true" : "false" },
          "data_mode": dataMode.rawValue,
          "cursor": cursor,
          "limit": String(limit)
        ]
      )
    }
    return try await APIClient.shared.get(
      "/v1/feedback",
      query: [
        "team_id": teamId,
        "status": status?.rawValue,
        "app_id": appId,
        "is_dev": isDev.map { $0 ? "true" : "false" },
        "data_mode": dataMode.rawValue,
        "cursor": cursor,
        "limit": String(limit)
      ]
    )
  }

  static func detail(projectId: String, feedbackId: String) async throws -> FeedbackDetail {
    try await APIClient.shared.get("/v1/projects/\(projectId)/feedback/\(feedbackId)")
  }

  static func updateStatus(
    projectId: String,
    feedbackId: String,
    status: FeedbackStatus
  ) async throws -> Feedback {
    struct Body: Encodable { let status: String }
    struct Envelope: Decodable { let feedback: Feedback }
    let envelope: Envelope = try await APIClient.shared.patch(
      "/v1/projects/\(projectId)/feedback/\(feedbackId)",
      body: Body(status: status.rawValue)
    )
    return envelope.feedback
  }

  static func remove(projectId: String, feedbackId: String) async throws {
    struct Envelope: Decodable { let deleted: Bool }
    let _: Envelope = try await APIClient.shared.delete(
      "/v1/projects/\(projectId)/feedback/\(feedbackId)"
    )
  }
}
