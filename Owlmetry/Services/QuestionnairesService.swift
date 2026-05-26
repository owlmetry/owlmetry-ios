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

  static func list(
    teamId: String,
    dataMode: DataMode,
    isActive: Bool? = nil
  ) async throws -> QuestionnaireListDTO {
    try await APIClient.shared.get(
      "/v1/questionnaires",
      query: [
        "team_id": teamId,
        "data_mode": dataMode.rawValue,
        "is_active": isActive.map { $0 ? "true" : "false" }
      ]
    )
  }

  static func detail(
    projectId: String,
    questionnaireId: String,
    dataMode: DataMode
  ) async throws -> Questionnaire {
    try await APIClient.shared.get(
      "/v1/projects/\(projectId)/questionnaires/\(questionnaireId)",
      query: ["data_mode": dataMode.rawValue]
    )
  }

  static func responses(
    projectId: String,
    questionnaireId: String,
    dataMode: DataMode,
    limit: Int = 50,
    submittedOnly: Bool = false,
    cursor: String? = nil
  ) async throws -> QuestionnaireResponsesListDTO {
    try await APIClient.shared.get(
      "/v1/projects/\(projectId)/questionnaires/\(questionnaireId)/responses",
      query: [
        "data_mode": dataMode.rawValue,
        "limit": String(limit),
        "submitted_only": submittedOnly ? "true" : nil,
        "cursor": cursor
      ]
    )
  }

  static func responseDetail(
    projectId: String,
    questionnaireId: String,
    responseId: String
  ) async throws -> QuestionnaireResponseDetail {
    try await APIClient.shared.get(
      "/v1/projects/\(projectId)/questionnaires/\(questionnaireId)/responses/\(responseId)"
    )
  }

  static func analytics(
    projectId: String,
    questionnaireId: String,
    dataMode: DataMode,
    submittedOnly: Bool = false
  ) async throws -> QuestionnaireAnalytics {
    try await APIClient.shared.get(
      "/v1/projects/\(projectId)/questionnaires/\(questionnaireId)/analytics",
      query: [
        "data_mode": dataMode.rawValue,
        "submitted_only": submittedOnly ? "true" : nil
      ]
    )
  }
}
