import Foundation

struct Project: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let teamId: String
  let name: String
  let slug: String
  let color: String
  let createdAt: String
  let updatedAt: String?
  let retentionDaysEvents: Int?
  let retentionDaysMetrics: Int?
  let retentionDaysFunnels: Int?
  let attachmentUserQuotaBytes: Int?
  let attachmentProjectQuotaBytes: Int?
}

struct ProjectsListDTO: Decodable {
  let projects: [Project]
}
