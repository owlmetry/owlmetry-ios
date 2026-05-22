import Foundation

enum StatsService {
  static func bucketed(
    kind: StatsKind,
    teamId: String,
    projectId: String?,
    days: Int,
    dataMode: DataMode,
    slug: String? = nil
  ) async throws -> StatsBucketedResponse {
    if let projectId {
      return try await APIClient.shared.get(
        "/v1/projects/\(projectId)/stats/\(kind.rawValue)/daily",
        query: [
          "days": String(days),
          "data_mode": dataMode.rawValue,
          "slug": slug
        ]
      )
    }
    return try await APIClient.shared.get(
      "/v1/stats/\(kind.rawValue)/daily",
      query: [
        "team_id": teamId,
        "days": String(days),
        "data_mode": dataMode.rawValue,
        "slug": slug
      ]
    )
  }
}
