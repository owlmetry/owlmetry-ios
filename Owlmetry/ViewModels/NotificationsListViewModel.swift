import Combine
import Foundation
import Owlmetry

@MainActor
final class NotificationsListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var notifications: [OwlmetryNotification] = []
  @Published private(set) var unreadCount: Int = 0

  /// User-visible filter — defaults to "Unread" so the list opens to what
  /// matters; tap "All" to see everything.
  enum ReadFilter: String, CaseIterable, Hashable {
    case unread, all, read

    var label: String {
      switch self {
      case .unread: return "Unread"
      case .all: return "All"
      case .read: return "Read"
      }
    }

    var apiValue: String? {
      switch self {
      case .unread: return "unread"
      case .read: return "read"
      case .all: return nil
      }
    }
  }

  @Published var filter: ReadFilter = .unread

  func reload() async {
    state = .loading
    do {
      let dto = try await NotificationsService.list(readState: filter.apiValue, limit: 100)
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
    do {
      _ = try await NotificationsService.markAllRead()
      await reload()
    } catch {
      Owl.error("notifications.read_all.failed", attributes: ["error": "\(error)"])
    }
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
