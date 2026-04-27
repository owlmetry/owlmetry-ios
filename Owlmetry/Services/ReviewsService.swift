import Foundation

enum ReviewsService {
  static func list(
    teamId: String,
    projectId: String? = nil,
    appId: String? = nil,
    store: ReviewStore? = nil,
    rating: Int? = nil,
    search: String? = nil,
    cursor: String? = nil,
    limit: Int = 50
  ) async throws -> ReviewsListDTO {
    let trimmedSearch = search?.trimmingCharacters(in: .whitespacesAndNewlines)
    let searchValue: String? = (trimmedSearch?.isEmpty ?? true) ? nil : trimmedSearch

    if let projectId {
      return try await APIClient.shared.get(
        "/v1/projects/\(projectId)/reviews",
        query: [
          "app_id": appId,
          "store": store?.rawValue,
          "rating": rating.map(String.init),
          "search": searchValue,
          "cursor": cursor,
          "limit": String(limit)
        ]
      )
    }

    return try await APIClient.shared.get(
      "/v1/reviews",
      query: [
        "team_id": teamId,
        "app_id": appId,
        "store": store?.rawValue,
        "rating": rating.map(String.init),
        "search": searchValue,
        "cursor": cursor,
        "limit": String(limit)
      ]
    )
  }

  static func detail(projectId: String, reviewId: String) async throws -> Review {
    try await APIClient.shared.get("/v1/projects/\(projectId)/reviews/\(reviewId)")
  }
}
