import Combine
import Foundation
import SwiftUI

/// Parsed deep link target. Mirrors the server's `link` strings on
/// notifications — `/dashboard/issues/<id>` → `.issue(id)`, etc. Unknown
/// shapes fall through as `.unknown(path)` so the UI can show a fallback.
enum DeepLink: Equatable {
  case issue(id: String, projectId: String?)
  case feedback(id: String, projectId: String?)
  case notifications
  case unknown(path: String)

  static func parse(_ raw: String) -> DeepLink {
    let trimmed = raw.split(separator: "?").first.map(String.init) ?? raw
    let parts = trimmed.split(separator: "/").map(String.init)
    // Expected shapes:
    //   /dashboard/issues/<id>
    //   /dashboard/feedback/<id>
    //   /dashboard/notifications
    if parts.count >= 3, parts[0] == "dashboard" {
      switch parts[1] {
      case "issues" where parts.count >= 3:
        return .issue(id: parts[2], projectId: nil)
      case "feedback" where parts.count >= 3:
        return .feedback(id: parts[2], projectId: nil)
      default:
        break
      }
    }
    if parts.count >= 2, parts[0] == "dashboard", parts[1] == "notifications" {
      return .notifications
    }
    return .unknown(path: raw)
  }
}

/// App-wide singleton observed by `MainTabView` to drive tab + nav-stack
/// changes when a notification or universal link arrives. Producers
/// (AppDelegate, NotificationsListView) write to `pendingDeepLink`; the
/// observer consumes it and clears the field.
@MainActor
final class DeepLinkRouter: ObservableObject {
  static let shared = DeepLinkRouter()

  @Published var pendingDeepLink: DeepLink?

  private init() {}

  func handle(_ link: String) {
    pendingDeepLink = DeepLink.parse(link)
  }

  func consume() -> DeepLink? {
    let value = pendingDeepLink
    pendingDeepLink = nil
    return value
  }
}
