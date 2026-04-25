import Foundation

struct MetricDefinition: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String
  let name: String
  let slug: String
  let description: String?
  let aggregationRules: [String: String]?
  let createdAt: String
  let updatedAt: String?
}

struct MetricAggregation: Codable, Equatable, Hashable {
  let totalCount: Int?
  let startCount: Int?
  let completeCount: Int?
  let failCount: Int?
  let cancelCount: Int?
  let recordCount: Int?
  let durationAvgMs: Double?
  let durationP50Ms: Double?
  let durationP95Ms: Double?
  let durationP99Ms: Double?
  let successRate: Double?
  let uniqueUsers: Int?
  let errorBreakdown: [MetricErrorBreakdownEntry]?
  let groups: [MetricGroup]?
}

struct MetricErrorBreakdownEntry: Codable, Equatable, Hashable {
  let error: String
  let count: Int
}

struct MetricGroup: Codable, Equatable, Hashable {
  let key: String
  let value: String?
  let totalCount: Int?
  let completeCount: Int?
  let failCount: Int?
  let successRate: Double?
  let durationAvgMs: Double?
}

struct MetricAggregationResponse: Decodable {
  let slug: String
  let aggregation: MetricAggregation
}

struct StoredMetricEvent: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let metricSlug: String
  let phase: MetricPhase
  let trackingId: String?
  let userId: String?
  let sessionId: String?
  let appId: String?
  let appVersion: String?
  let environment: String?
  let durationMs: Double?
  let error: String?
  let timestamp: String
}

struct MetricEventsListDTO: Decodable {
  let events: [StoredMetricEvent]
  let cursor: String?
  let hasMore: Bool?
}

struct MetricsListDTO: Decodable {
  let metrics: [MetricDefinition]
}
