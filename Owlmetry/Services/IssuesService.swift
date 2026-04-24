import Foundation

enum IssuesService {
  static func list(
    teamId: String,
    projectId: String?,
    dataMode: DataMode,
    status: IssueStatus? = nil,
    appId: String? = nil,
    isDev: Bool? = nil,
    cursor: String? = nil,
    limit: Int = 50
  ) async throws -> IssuesListDTO {
    if let projectId {
      return try await APIClient.shared.get(
        "/v1/projects/\(projectId)/issues",
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
      "/v1/issues",
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

  static func detail(projectId: String, issueId: String) async throws -> IssueDetail {
    try await APIClient.shared.get("/v1/projects/\(projectId)/issues/\(issueId)")
  }

  static func updateStatus(
    projectId: String,
    issueId: String,
    status: IssueStatus,
    resolvedAtVersion: String? = nil
  ) async throws -> Issue {
    struct Body: Encodable {
      let status: String
      let resolvedAtVersion: String?
    }
    struct Envelope: Decodable {
      let issue: Issue
    }
    let envelope: Envelope = try await APIClient.shared.patch(
      "/v1/projects/\(projectId)/issues/\(issueId)",
      body: Body(status: status.rawValue, resolvedAtVersion: resolvedAtVersion)
    )
    return envelope.issue
  }
}
