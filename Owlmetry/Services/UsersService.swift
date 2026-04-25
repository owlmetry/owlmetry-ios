import Foundation

enum UsersService {
  enum Sort: String {
    case firstSeen = "first_seen"
    case lastSeen = "last_seen"
  }

  static func list(
    teamId: String,
    projectId: String?,
    appId: String? = nil,
    search: String? = nil,
    isAnonymous: Bool? = nil,
    billingStatuses: [BillingStatus] = [],
    since: String? = nil,
    until: String? = nil,
    sort: Sort = .lastSeen,
    cursor: String? = nil,
    limit: Int = 40
  ) async throws -> UsersListDTO {
    try await APIClient.shared.get(
      "/v1/app-users",
      query: [
        "team_id": teamId,
        "project_id": projectId,
        "app_id": appId,
        "search": search,
        "is_anonymous": isAnonymous.map { $0 ? "true" : "false" },
        "billing_status": billingStatuses.isEmpty ? nil : billingStatuses.map { $0.rawValue }.joined(separator: ","),
        "since": since,
        "until": until,
        "sort": sort.rawValue,
        "cursor": cursor,
        "limit": String(limit)
      ]
    )
  }

  static func detail(appUserId: String) async throws -> AppUser {
    struct Envelope: Decodable { let user: AppUser }
    let envelope: Envelope = try await APIClient.shared.get("/v1/app-users/\(appUserId)")
    return envelope.user
  }
}
