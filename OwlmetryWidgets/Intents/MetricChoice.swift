import AppIntents

/// Widget-configurable metric. 1:1 with `DashboardMetric` (which lives in the
/// shared layer) but kept separate so the App Intents enum owns its display
/// strings and ordering in the Edit Widget picker.
enum MetricChoice: String, AppEnum {
  case openIssues
  case events
  case users
  case sessions
  case metrics
  case funnels
  case feedback
  case responses
  case reviews
  case avgRating

  static var typeDisplayRepresentation: TypeDisplayRepresentation { "Metric" }

  static var caseDisplayRepresentations: [MetricChoice: DisplayRepresentation] {
    [
      .openIssues: "Open Issues",
      .events: "Events",
      .users: "Users",
      .sessions: "Sessions",
      .metrics: "Metrics",
      .funnels: "Funnels",
      .feedback: "New Feedback",
      .responses: "Responses",
      .reviews: "Reviews",
      .avgRating: "Avg Rating",
    ]
  }

  var metric: DashboardMetric {
    switch self {
    case .openIssues: return .openIssues
    case .events: return .events
    case .users: return .users
    case .sessions: return .sessions
    case .metrics: return .metrics
    case .funnels: return .funnels
    case .feedback: return .feedback
    case .responses: return .responses
    case .reviews: return .reviews
    case .avgRating: return .avgRating
    }
  }
}

/// Curated metric sets for the large widget, so the user picks an intent rather
/// than configuring many individual slots.
enum PresetChoice: String, AppEnum {
  case overview
  case engagement
  case appStore
  case everything

  static var typeDisplayRepresentation: TypeDisplayRepresentation { "Preset" }

  static var caseDisplayRepresentations: [PresetChoice: DisplayRepresentation] {
    [
      .overview: "Overview",
      .engagement: "Engagement",
      .appStore: "App Store",
      .everything: "Everything",
    ]
  }

  var metrics: [DashboardMetric] {
    switch self {
    case .overview: return [.openIssues, .events, .users, .sessions, .metrics, .funnels]
    case .engagement: return [.metrics, .funnels, .responses, .feedback]
    case .appStore: return [.reviews, .avgRating]
    case .everything: return DashboardMetric.allCases
    }
  }
}
