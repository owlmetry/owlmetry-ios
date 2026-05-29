import Foundation

enum MetricsService {
  static func list(projectId: String) async throws -> [MetricDefinition] {
    let dto: MetricsListDTO = try await APIClient.shared.get("/v1/projects/\(projectId)/metrics")
    return dto.metrics
  }

  static func aggregation(
    slug: String,
    projectId: String,
    since: String?,
    until: String? = nil,
    dataMode: DataMode
  ) async throws -> MetricAggregation {
    let response: MetricAggregationResponse = try await APIClient.shared.get(
      "/v1/projects/\(projectId)/metrics/\(slug)/query",
      query: [
        "since": since,
        "until": until,
        "data_mode": dataMode.rawValue
      ]
    )
    return response.aggregation
  }

  static func completionsCount(
    teamId: String,
    projectId: String?,
    since: String,
    dataMode: DataMode
  ) async throws -> CompletionsCountResponse {
    try await APIClient.shared.get(
      "/v1/metrics/completions/count",
      query: [
        "team_id": teamId,
        "project_id": projectId,
        "since": since,
        "data_mode": dataMode.rawValue
      ]
    )
  }

  static func stats(
    projectId: String,
    since: String? = nil,
    until: String? = nil,
    dataMode: DataMode
  ) async throws -> [MetricStatsEntry] {
    let response: MetricStatsResponse = try await APIClient.shared.get(
      "/v1/projects/\(projectId)/metric-stats",
      query: [
        "since": since,
        "until": until,
        "data_mode": dataMode.rawValue
      ]
    )
    return response.stats
  }

  static func events(
    slug: String,
    projectId: String,
    dataMode: DataMode,
    phase: MetricPhase? = nil,
    cursor: String? = nil,
    limit: Int = 25
  ) async throws -> MetricEventsListDTO {
    try await APIClient.shared.get(
      "/v1/projects/\(projectId)/metrics/\(slug)/events",
      query: [
        "phase": phase?.rawValue,
        "data_mode": dataMode.rawValue,
        "cursor": cursor,
        "limit": String(limit)
      ]
    )
  }
}
