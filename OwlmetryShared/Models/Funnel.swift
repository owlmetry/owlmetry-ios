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
  let eventFilter: FunnelStepFilter?

  var id: String { name }
}

struct FunnelStepFilter: Codable, Equatable, Hashable {
  let stepName: String?
  let screenName: String?
}

struct FunnelAnalytics: Codable, Equatable, Hashable {
  let funnel: FunnelDefinition?
  let mode: String?
  let totalUsers: Int?
  let steps: [FunnelStepAnalytics]
  let breakdown: [FunnelBreakdownGroup]?

  var totalStarts: Int? { steps.first?.uniqueUsers }
  var totalCompletions: Int? { steps.last?.uniqueUsers }
  var conversionRate: Double? {
    guard let starts = totalStarts, starts > 0, let completions = totalCompletions else { return nil }
    return Double(completions) / Double(starts)
  }
}

struct FunnelStepAnalytics: Codable, Equatable, Hashable, Identifiable {
  let stepIndex: Int
  let stepName: String
  let uniqueUsers: Int
  let percentage: Double
  let dropOffCount: Int
  let dropOffPercentage: Double

  var id: String { "\(stepIndex)-\(stepName)" }
  var name: String { stepName }
  var order: Int? { stepIndex }
  var count: Int? { uniqueUsers }
  var dropOff: Int? { dropOffCount }
  var conversionFromStart: Double? { percentage / 100 }
  var conversionFromPrevious: Double? {
    let survival = 100 - dropOffPercentage
    return stepIndex == 0 ? nil : survival / 100
  }
}

struct FunnelBreakdownGroup: Codable, Equatable, Hashable {
  let key: String
  let value: String
  let totalUsers: Int
  let steps: [FunnelStepAnalytics]
}

struct FunnelAnalyticsResponse: Decodable {
  let slug: String
  let analytics: FunnelAnalytics
}

struct FunnelsListDTO: Decodable {
  let funnels: [FunnelDefinition]
}
