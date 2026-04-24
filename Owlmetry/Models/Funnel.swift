import Foundation

struct FunnelDefinition: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String
  let name: String
  let slug: String
  let description: String?
  let steps: [FunnelStep]
  let createdAt: String
  let updatedAt: String?
}

struct FunnelStep: Codable, Identifiable, Equatable, Hashable {
  let name: String
  let order: Int?
  let eventFilter: FunnelStepFilter?

  var id: String { "\(order ?? 0)-\(name)" }
}

struct FunnelStepFilter: Codable, Equatable, Hashable {
  let stepName: String?
  let screenName: String?
}

struct FunnelAnalytics: Codable, Equatable, Hashable {
  let totalStarts: Int?
  let totalCompletions: Int?
  let conversionRate: Double?
  let steps: [FunnelStepAnalytics]
}

struct FunnelStepAnalytics: Codable, Equatable, Hashable, Identifiable {
  let name: String
  let order: Int?
  let uniqueUsers: Int?
  let count: Int?
  let dropOff: Int?
  let conversionFromPrevious: Double?
  let conversionFromStart: Double?

  var id: String { "\(order ?? 0)-\(name)" }
}

struct FunnelAnalyticsResponse: Decodable {
  let slug: String
  let analytics: FunnelAnalytics
}

struct FunnelsListDTO: Decodable {
  let funnels: [FunnelDefinition]
}
