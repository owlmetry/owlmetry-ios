import Foundation

enum StatsKind: String {
  case events
  case users
  case sessions
  case metricCompletions = "metric_completions"
  case funnelCompletions = "funnel_completions"
  case questionnaireResponses = "questionnaire_responses"
}

struct StatsBucketedPoint: Decodable, Equatable {
  let bucket: String
  let value: Double
}

struct StatsBucketedResponse: Decodable, Equatable {
  let kind: String
  let grain: String
  let from: String
  let to: String
  let data: [StatsBucketedPoint]
}
