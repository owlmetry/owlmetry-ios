import Foundation

enum QuestionnairesService {
  static func count(
    teamId: String,
    projectId: String?,
    since: String?,
    dataMode: DataMode
  ) async throws -> Int {
    struct Envelope: Decodable { let count: Int }
    let envelope: Envelope = try await APIClient.shared.get(
      "/v1/questionnaires/count",
      query: [
        "team_id": teamId,
        "project_id": projectId,
        "since": since,
        "data_mode": dataMode.rawValue
      ]
    )
    return envelope.count
  }
}
