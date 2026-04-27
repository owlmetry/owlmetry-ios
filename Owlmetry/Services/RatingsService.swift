import Foundation

enum RatingsService {
  // Per-country breakdown for a single app + worldwide summary.
  static func appRatings(
    projectId: String,
    appId: String,
    store: ReviewStore? = nil
  ) async throws -> AppRatingsDTO {
    try await APIClient.shared.get(
      "/v1/projects/\(projectId)/apps/\(appId)/ratings",
      query: ["store": store?.rawValue]
    )
  }

  // Project-wide or team-wide aggregate by country. Project takes precedence.
  static func byCountry(
    teamId: String,
    projectId: String? = nil,
    appId: String? = nil,
    store: ReviewStore? = nil
  ) async throws -> RatingsByCountryDTO {
    if let projectId {
      return try await APIClient.shared.get(
        "/v1/projects/\(projectId)/ratings/by-country",
        query: [
          "app_id": appId,
          "store": store?.rawValue
        ]
      )
    }
    return try await APIClient.shared.get(
      "/v1/ratings/by-country",
      query: [
        "team_id": teamId,
        "app_id": appId,
        "store": store?.rawValue
      ]
    )
  }

  // Trigger a manual sync — admin only.
  static func sync(projectId: String) async throws -> SyncResponse {
    try await APIClient.shared.post(
      "/v1/projects/\(projectId)/ratings/sync",
      body: EmptyBody()
    )
  }

  struct SyncResponse: Decodable {
    let syncing: Bool
    let total: Int
    let jobRunId: String?
  }

  private struct EmptyBody: Encodable {}
}
