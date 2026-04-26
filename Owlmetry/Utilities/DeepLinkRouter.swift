import Combine
import Foundation
import SwiftUI

/// Parsed deep link target. Mirrors the server's `link` strings on
/// notifications, with project context pulled from the APNs `data` payload
/// when present.
enum DeepLink: Equatable {
  case issue(id: String, projectId: String?)
  case feedback(id: String, projectId: String?)
  case issuesList(projectId: String?)
  case feedbackList(projectId: String?)
  case usersList
  case insights
  case notifications
  case unknown(path: String)

  static func parse(_ raw: String, data: [String: Any]? = nil) -> DeepLink {
    let projectId = (data?["project_id"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    let trimmed = raw.split(separator: "?").first.map(String.init) ?? raw
    let parts = trimmed.split(separator: "/").map(String.init)
    if parts.count >= 2, parts[0] == "dashboard" {
      switch parts[1] {
      case "issues":
        if parts.count >= 3 {
          return .issue(id: parts[2], projectId: projectId)
        }
        return .issuesList(projectId: projectId)
      case "feedback":
        if parts.count >= 3 {
          return .feedback(id: parts[2], projectId: projectId)
        }
        return .feedbackList(projectId: projectId)
      case "notifications":
        return .notifications
      default:
        break
      }
    }
    return .unknown(path: raw)
  }
}

/// Hashable routes pushed onto per-tab NavigationStacks when a deep link
/// arrives. The matching `.navigationDestination(for:)` modifiers in
/// `MainTabView` resolve them to the loader views that fetch by id.
struct IssueDeepLinkRoute: Hashable {
  let id: String
  let projectId: String
}

struct FeedbackDeepLinkRoute: Hashable {
  let id: String
  let projectId: String
}

struct NotificationsDeepLinkRoute: Hashable {}

/// App-wide singleton observed by `MainTabView` to drive tab + nav-stack
/// changes when a notification or universal link arrives. Producers
/// (AppDelegate, NotificationsListView) write to `pendingDeepLink`; the
/// observer consumes it and clears the field.
@MainActor
final class DeepLinkRouter: ObservableObject {
  static let shared = DeepLinkRouter()

  @Published var pendingDeepLink: DeepLink?

  private init() {}

  func handle(_ link: String, data: [String: Any]? = nil) {
    pendingDeepLink = DeepLink.parse(link, data: data)
  }

  func consume() -> DeepLink? {
    let value = pendingDeepLink
    pendingDeepLink = nil
    return value
  }
}
