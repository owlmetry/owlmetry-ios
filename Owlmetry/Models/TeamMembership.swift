import Foundation

struct TeamMembership: Codable, Equatable, Identifiable {
  let id: String
  let name: String
  let slug: String
  let role: String
  let defaultAgentKey: String?
}
