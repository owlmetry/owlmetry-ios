import Foundation

enum AppsService {
  static func list(teamId: String, projectId: String? = nil) async throws -> [AppModel] {
    let dto: AppsListDTO = try await APIClient.shared.get(
      "/v1/apps",
      query: [
        "team_id": teamId,
        "project_id": projectId
      ]
    )
    return dto.apps
  }
}
