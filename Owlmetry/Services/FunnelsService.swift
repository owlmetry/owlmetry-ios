import Foundation

enum FunnelsService {
  static func list(projectId: String) async throws -> [FunnelDefinition] {
    let dto: FunnelsListDTO = try await APIClient.shared.get("/v1/projects/\(projectId)/funnels")
    return dto.funnels
  }

  static func analytics(
    slug: String,
    projectId: String,
    since: String?,
    until: String? = nil,
    dataMode: DataMode
  ) async throws -> FunnelAnalytics {
    let response: FunnelAnalyticsResponse = try await APIClient.shared.get(
      "/v1/projects/\(projectId)/funnels/\(slug)/query",
      query: [
        "since": since,
        "until": until,
        "data_mode": dataMode.rawValue
      ]
    )
    return response.analytics
  }

  static func completionsCount(
    teamId: String,
    projectId: String?,
    since: String,
    dataMode: DataMode
  ) async throws -> CompletionsCountResponse {
    try await APIClient.shared.get(
      "/v1/funnels/completions/count",
      query: [
        "team_id": teamId,
        "project_id": projectId,
        "since": since,
        "data_mode": dataMode.rawValue
      ]
    )
  }
}
