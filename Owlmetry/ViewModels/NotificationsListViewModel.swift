import Combine
import Foundation
import Owlmetry

@MainActor
final class NotificationsListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var notifications: [OwlmetryNotification] = []
  @Published private(set) var unreadCount: Int = 0

  func reload() async {
    state = .loading
    do {
      let dto = try await NotificationsService.list(readState: nil, limit: 100)
      notifications = dto.notifications
      state = notifications.isEmpty ? .empty : .loaded(())
      await refreshUnread()
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load notifications")
      Owl.error("notifications.list.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
      Owl.error("notifications.list.failed", attributes: ["error": "\(error)"])
    }
  }

  func refreshUnread() async {
    do {
      let dto = try await NotificationsService.unreadCount()
      if dto.count != unreadCount { unreadCount = dto.count }
      InboxBadgeStore.shared.set(dto.count)
    } catch {
      // Non-fatal — badge just won't update this cycle.
    }
  }

  func markRead(_ id: String) async {
    if let i = notifications.firstIndex(where: { $0.id == id }) {
      let n = notifications[i]
      notifications[i] = OwlmetryNotification(
        id: n.id, type: n.type, title: n.title, body: n.body, link: n.link,
        teamId: n.teamId, readAt: ISO8601DateFormatter().string(from: Date()), createdAt: n.createdAt,
      )
    }
    do {
      try await NotificationsService.markRead(id: id)
      await refreshUnread()
    } catch {
      Owl.error("notifications.read.failed", attributes: ["error": "\(error)"])
      await reload()
    }
  }

  func markAllRead() async {
    // Optimistic: clear local + shared store + home-screen badge before the
    // network round-trip so peer views (dashboard avatar, profile row) update
    // synchronously when the inbox is dismissed.
    unreadCount = 0
    InboxBadgeStore.shared.set(0)
    do {
      _ = try await NotificationsService.markAllRead()
      await reload()
    } catch {
      Owl.error("notifications.read_all.failed", attributes: ["error": "\(error)"])
    }
  }

  /// No-op when there is nothing unread. Used by `NotificationsListView.onDisappear`
  /// so navigating back from the inbox clears the unread state automatically.
  func markAllReadIfNeeded() async {
    guard unreadCount > 0 else { return }
    await markAllRead()
  }

  func remove(_ id: String) async {
    notifications.removeAll(where: { $0.id == id })
    do {
      try await NotificationsService.delete(id: id)
      await refreshUnread()
    } catch {
      Owl.error("notifications.delete.failed", attributes: ["error": "\(error)"])
      await reload()
    }
  }
}
