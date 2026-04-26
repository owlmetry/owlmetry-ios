import Combine
import Foundation
import UserNotifications

/// Single source of truth for the unread inbox count, observed by every view
/// that renders an indicator (dashboard avatar, profile inbox row). Without
/// this, each view's `NotificationsListViewModel` keeps its own count and
/// can't see a peer's mark-read until its next periodic refresh.
@MainActor
final class InboxBadgeStore: ObservableObject {
  static let shared = InboxBadgeStore()

  @Published private(set) var unreadCount: Int = 0

  private init() {}

  /// Updates the in-app count and the home-screen icon badge in one step.
  func set(_ value: Int) {
    let clamped = max(0, value)
    if unreadCount != clamped { unreadCount = clamped }
    UNUserNotificationCenter.current().setBadgeCount(clamped) { _ in }
  }
}
