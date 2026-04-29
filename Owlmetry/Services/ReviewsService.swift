import Foundation

enum ReviewsService {
  static func count(
    teamId: String,
    projectId: String? = nil,
    since: String? = nil
  ) async throws -> Int {
    struct CountResponse: Decodable { let count: Int }
    let response: CountResponse = try await APIClient.shared.get(
      "/v1/reviews/count",
      query: [
        "team_id": teamId,
        "project_id": projectId,
        "since": since
      ]
    )
    return response.count
  }

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

  struct RespondRequest: Encodable { let body: String }

  static func respond(
    projectId: String,
    reviewId: String,
    body: String
  ) async throws -> Review {
    try await APIClient.shared.put(
      "/v1/projects/\(projectId)/reviews/\(reviewId)/response",
      body: RespondRequest(body: body)
    )
  }

  /// Removes the developer response on Apple's side. Irrecoverable.
  static func deleteResponse(projectId: String, reviewId: String) async throws -> Review {
    try await APIClient.shared.delete(
      "/v1/projects/\(projectId)/reviews/\(reviewId)/response"
    )
  }
}
