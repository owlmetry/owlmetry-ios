import Combine
import Foundation
import Owlmetry

enum UsersTimeRange: String, CaseIterable, Identifiable {
  case allTime
  case last24h
  case last7d
  case last30d

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .allTime: return "All time"
    case .last24h: return "Last 24 hours"
    case .last7d: return "Last 7 days"
    case .last30d: return "Last 30 days"
    }
  }

  var since: String? {
    switch self {
    case .allTime: return nil
    case .last24h: return ISODate.isoString(since: 86_400)
    case .last7d: return ISODate.isoString(since: 86_400 * 7)
    case .last30d: return ISODate.isoString(since: 86_400 * 30)
    }
  }
}

enum UserTypeFilter: String, CaseIterable, Identifiable {
  case all
  case real
  case anon

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .all: return "All users"
    case .real: return "👤 Real"
    case .anon: return "👻 Anonymous"
    }
  }

  var isAnonymous: Bool? {
    switch self {
    case .all: return nil
    case .real: return false
    case .anon: return true
    }
  }
}

struct UsersFilter: Equatable {
  var appId: String? = nil
  var timeRange: UsersTimeRange = .allTime
  var type: UserTypeFilter = .all
  var billing: Set<BillingStatus> = []
  var search: String = ""
  var sort: UsersService.Sort = .lastSeen

  var hashDescription: String {
    let billingKey = billing.map { $0.rawValue }.sorted().joined(separator: ",")
    return "\(appId ?? "-")|\(timeRange.rawValue)|\(type.rawValue)|\(billingKey)|\(search)|\(sort.rawValue)"
  }
}

@MainActor
final class UsersListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var users: [AppUser] = []
  @Published var filter = UsersFilter()
  @Published private(set) var isLoadingMore = false
  @Published private(set) var hasMore = false
  private var cursor: String?

  var hasActiveFilters: Bool {
    filter.appId != nil || filter.timeRange != .allTime || filter.type != .all || !filter.billing.isEmpty || !filter.search.isEmpty
  }

  func load(teamId: String, projectId: String?, dataMode: DataMode, search: String? = nil) async {
    state = .loading
    cursor = nil
    let effectiveSearch = search ?? filter.search
    do {
      let dto = try await UsersService.list(
        teamId: teamId,
        projectId: projectId,
        appId: filter.appId,
        search: effectiveSearch.isEmpty ? nil : effectiveSearch,
        isAnonymous: filter.type.isAnonymous,
        billingStatuses: Array(filter.billing),
        since: filter.timeRange.since,
        sort: filter.sort,
        cursor: nil
      )
      users = dto.users
      cursor = dto.cursor
      hasMore = dto.hasMore ?? false
      state = users.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load users")
      Owl.error("users.list.failed", attributes: ["error": "\(error)"])
    } catch {
      state = .error(error.localizedDescription)
      Owl.error("users.list.failed", attributes: ["error": "\(error)"])
    }
  }

  func loadMoreIfNeeded(teamId: String, projectId: String?, dataMode: DataMode, currentUser: AppUser) async {
    guard hasMore, !isLoadingMore, let cursor, let last = users.last, last.id == currentUser.id else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let dto = try await UsersService.list(
        teamId: teamId,
        projectId: projectId,
        appId: filter.appId,
        search: filter.search.isEmpty ? nil : filter.search,
        isAnonymous: filter.type.isAnonymous,
        billingStatuses: Array(filter.billing),
        since: filter.timeRange.since,
        sort: filter.sort,
        cursor: cursor
      )
      users.append(contentsOf: dto.users)
      self.cursor = dto.cursor
      hasMore = dto.hasMore ?? false
    } catch {
      Owl.error("users.list.load_more.failed", attributes: ["error": "\(error)"])
    }
  }
}
