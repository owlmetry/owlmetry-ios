import Foundation

struct EventsCountResponse: Decodable, Equatable {
  let count: Int
  let uniqueUsers: Int
  let uniqueSessions: Int
}

struct CompletionsCountResponse: Decodable, Equatable {
  let count: Int
  let started: Int?
  let failed: Int?
}

struct MetricStatsEntry: Decodable, Equatable, Hashable {
  let slug: String
  let completeCount: Int
  let failCount: Int
  let successRate: Double?
}

struct MetricStatsResponse: Decodable, Equatable {
  let stats: [MetricStatsEntry]
}
