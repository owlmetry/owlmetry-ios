import Foundation

/// The metrics surfaced on the dashboard and offered as widget choices. Carries
/// the display metadata (label, SF Symbol, deep-link target) so the app cards
/// and the widgets render from one definition — mirrors `DashboardView.cards`.
enum DashboardMetric: String, CaseIterable, Identifiable, Hashable {
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

  var id: String { rawValue }

  var label: String {
    switch self {
    case .openIssues: return "Open Issues"
    case .events: return "Events · 24h"
    case .users: return "Users · 24h"
    case .sessions: return "Sessions · 24h"
    case .metrics: return "Metrics · 24h"
    case .funnels: return "Funnels · 24h"
    case .feedback: return "New Feedback"
    case .responses: return "Responses · 24h"
    case .reviews: return "Reviews"
    case .avgRating: return "Avg Rating"
    }
  }

  var systemImage: String {
    switch self {
    case .openIssues: return "ladybug"
    case .events: return "scroll"
    case .users: return "person.crop.circle.badge.magnifyingglass"
    case .sessions: return "point.3.connected.trianglepath.dotted"
    case .metrics: return "checkmark.circle"
    case .funnels: return "line.3.horizontal.decrease.circle"
    case .feedback: return "bubble.left"
    case .responses: return "list.clipboard"
    case .reviews: return "star.bubble"
    case .avgRating: return "star"
    }
  }

  /// Path consumed by `DeepLink.parse` when a widget tap opens the app — matches
  /// the `deepLink` each dashboard card already uses.
  var deepLinkPath: String {
    switch self {
    case .openIssues: return "dashboard/issues"
    case .events, .users, .sessions: return "dashboard/users"
    case .metrics, .funnels: return "dashboard/insights"
    case .feedback: return "dashboard/feedback"
    case .responses: return "dashboard/questionnaires"
    case .reviews: return "dashboard/reviews"
    case .avgRating: return "dashboard/ratings"
    }
  }

  /// Whether this metric carries a 30-day sparkline (the rest render a flat
  /// count). Matches which dashboard cards pass `sparklineValues`.
  var hasSparkline: Bool {
    switch self {
    case .events, .users, .sessions, .metrics, .funnels, .responses: return true
    case .openIssues, .feedback, .reviews, .avgRating: return false
    }
  }
}
