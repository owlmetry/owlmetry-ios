import Foundation

enum DataMode: String, Codable, CaseIterable, Identifiable {
  case production
  case development
  case all

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .production: return "Production"
    case .development: return "Development"
    case .all: return "All"
    }
  }

  var emoji: String {
    switch self {
    case .production: return "🟢"
    case .development: return "🛠️"
    case .all: return "🌐"
    }
  }
}

enum IssueStatus: String, Codable, CaseIterable, Identifiable {
  case new
  case inProgress = "in_progress"
  case regressed
  case resolved
  case silenced

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .new: return "New"
    case .inProgress: return "In Progress"
    case .regressed: return "Regressed"
    case .resolved: return "Resolved"
    case .silenced: return "Silenced"
    }
  }

  var emoji: String {
    switch self {
    case .new: return "🆕"
    case .inProgress: return "🔧"
    case .regressed: return "🔄"
    case .resolved: return "✅"
    case .silenced: return "🔇"
    }
  }

  static let openStatuses: [IssueStatus] = [.new, .inProgress, .regressed]
}

enum FeedbackStatus: String, Codable, CaseIterable, Identifiable {
  case new
  case inReview = "in_review"
  case addressed
  case dismissed

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .new: return "New"
    case .inReview: return "In Review"
    case .addressed: return "Addressed"
    case .dismissed: return "Dismissed"
    }
  }

  var emoji: String {
    switch self {
    case .new: return "🆕"
    case .inReview: return "👀"
    case .addressed: return "✅"
    case .dismissed: return "🚫"
    }
  }
}

enum MetricPhase: String, Codable, CaseIterable, Identifiable {
  case start
  case complete
  case fail
  case cancel
  case record

  var id: String { rawValue }

  var displayName: String {
    rawValue.capitalized
  }

  var emoji: String {
    switch self {
    case .start: return "🚀"
    case .complete: return "✅"
    case .fail: return "❌"
    case .cancel: return "🚫"
    case .record: return "📝"
    }
  }
}

enum AppPlatform: String, Codable, CaseIterable, Identifiable {
  case apple
  case android
  case web
  case backend

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .apple: return "Apple"
    case .android: return "Android"
    case .web: return "Web"
    case .backend: return "Backend"
    }
  }

  var emoji: String {
    switch self {
    case .apple: return "🍎"
    case .android: return "🤖"
    case .web: return "🌐"
    case .backend: return "☁️"
    }
  }
}

enum AppEnvironment: String, Codable, CaseIterable, Identifiable {
  case ios
  case ipados
  case macos
  case android
  case web
  case backend

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .ios: return "iOS"
    case .ipados: return "iPadOS"
    case .macos: return "macOS"
    case .android: return "Android"
    case .web: return "Web"
    case .backend: return "Backend"
    }
  }
}

enum TeamRole: String, Codable, CaseIterable {
  case owner
  case admin
  case member

  var displayName: String { rawValue.capitalized }

  var emoji: String {
    switch self {
    case .owner: return "👑"
    case .admin: return "🛡️"
    case .member: return "👤"
    }
  }
}

enum BillingStatus: String, Codable, CaseIterable, Identifiable {
  case paid
  case trial
  case free

  var id: String { rawValue }

  var displayName: String { rawValue.capitalized }

  var emoji: String {
    switch self {
    case .paid: return "💰"
    case .trial: return "🎁"
    case .free: return "🆓"
    }
  }
}
