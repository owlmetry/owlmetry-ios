import Foundation

enum ProjectsService {
  static func list(teamId: String) async throws -> [Project] {
    let dto: ProjectsListDTO = try await APIClient.shared.get(
      "/v1/projects",
      query: ["team_id": teamId]
    )
    return dto.projects
  }
}
