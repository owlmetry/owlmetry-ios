import SwiftUI

enum Theme {
  static let cardBackground = Color(.secondarySystemBackground)
  static let cardBorder = Color(.separator).opacity(0.35)
  static let divider = Color(.separator)

  enum Status {
    static func color(for status: IssueStatus) -> Color {
      switch status {
      case .new: return .red
      case .inProgress: return .blue
      case .regressed: return .yellow
      case .resolved: return .green
      case .snoozed: return .yellow
      case .silenced: return .gray
      }
    }

    static func color(for status: FeedbackStatus) -> Color {
      switch status {
      case .new: return .red
      case .inReview: return .blue
      case .addressed: return .green
      case .dismissed: return .gray
      }
    }
  }

  enum Phase {
    static func color(for phase: MetricPhase) -> Color {
      switch phase {
      case .start: return .blue
      case .complete: return .green
      case .fail: return .red
      case .cancel: return .yellow
      case .record: return .cyan
      }
    }
  }

  enum Billing {
    static let paid: Color = .green
    static let trial: Color = Color(red: 0.22, green: 0.60, blue: 0.86)
    static let free: Color = .gray

    static func color(for status: BillingStatus) -> Color {
      switch status {
      case .paid: return paid
      case .trial: return trial
      case .free: return free
      }
    }
  }

  enum Attribution {
    static let sourced: Color = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let none: Color = .gray
  }

  enum User {
    static let real: Color = .accentColor
    static let anon: Color = .gray
  }
}
