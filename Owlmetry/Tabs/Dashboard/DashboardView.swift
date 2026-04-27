import Owlmetry
import SwiftUI

struct DashboardView: View {
  @EnvironmentObject private var auth: AuthViewModel
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = DashboardViewModel()
  @StateObject private var notifications = NotificationsListViewModel()
  @ObservedObject private var badgeStore = InboxBadgeStore.shared

  private let columns: [GridItem] = [
    GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 12)
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        lastUpdatedLabel
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(cards) { card in
            Button {
              Haptics.play(.light)
              DeepLinkRouter.shared.pendingDeepLink = card.deepLink
            } label: {
              StatCard(
                label: card.label,
                systemImage: card.systemImage,
                value: card.value,
                secondary: card.secondary,
                isLoading: card.isLoading
              )
            }
            .buttonStyle(.plain)
          }
        }
        if let error = viewModel.errorMessage {
          Text(error)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .navigationTitle("Dashboard")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        NavigationLink(destination: ProfileView()) {
          ProfileAvatarButton(initials: profileInitials, unread: badgeStore.unreadCount)
        }
      }
      if appState.projectsForCurrentTeam.count > 1 {
        ToolbarItem(placement: .topBarTrailing) {
          ProjectSelectorMenu()
        }
      }
    }
    .refreshable {
      await reload()
    }
    .autoRefresh(id: refreshKey, every: 30) {
      await reload()
      await notifications.refreshUnread()
    }
    .task {
      await notifications.refreshUnread()
    }
    .onAppear {
      // Re-runs after popping back from Profile/Inbox so the avatar badge
      // reflects a mark-all-read without waiting on the 30s auto-refresh.
      Task { await notifications.refreshUnread() }
    }
    .owlScreen("Dashboard")
  }

  private var profileInitials: String {
    let name = auth.currentUser?.name ?? auth.currentUser?.email ?? "?"
    let parts = name.split(separator: " ").prefix(2)
    if parts.count >= 2 {
      return parts.map { $0.prefix(1) }.joined().uppercased()
    }
    return String(name.prefix(2)).uppercased()
  }

  private var refreshKey: String {
    let team = appState.currentTeam?.id ?? "-"
    let proj = appState.selectedProjectId ?? "all"
    return "\(team)|\(proj)|\(appState.dataMode.rawValue)"
  }

  private var lastUpdatedLabel: some View {
    TimelineView(.periodic(from: .now, by: 15)) { context in
      Text(updatedString(at: context.date))
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func updatedString(at now: Date) -> String {
    guard let last = viewModel.lastUpdatedAt else { return " " }
    let seconds = Int(now.timeIntervalSince(last))
    if seconds < 60 { return "Updated just now" }
    if seconds < 3_600 {
      let m = seconds / 60
      return "Updated \(m)min ago"
    }
    if seconds < 86_400 {
      let h = seconds / 3_600
      return "Updated \(h)h ago"
    }
    let d = seconds / 86_400
    return "Updated \(d)d ago"
  }

  private var cards: [CardData] {
    [
      CardData(
        id: "open_issues",
        label: "Open Issues",
        systemImage: "ladybug",
        value: format(viewModel.openIssuesCount),
        isLoading: viewModel.openIssuesCount == nil,
        deepLink: .issuesList(projectId: nil)
      ),
      CardData(
        id: "events_24h",
        label: "Events · 24h",
        systemImage: "scroll",
        value: format(viewModel.eventsCount),
        isLoading: viewModel.eventsCount == nil,
        deepLink: .usersList
      ),
      CardData(
        id: "users_24h",
        label: "Users · 24h",
        systemImage: "person.crop.circle.badge.magnifyingglass",
        value: format(viewModel.uniqueUsers),
        isLoading: viewModel.uniqueUsers == nil,
        deepLink: .usersList
      ),
      CardData(
        id: "sessions_24h",
        label: "Sessions · 24h",
        systemImage: "point.3.connected.trianglepath.dotted",
        value: format(viewModel.uniqueSessions),
        isLoading: viewModel.uniqueSessions == nil,
        deepLink: .usersList
      ),
      CardData(
        id: "metrics_24h",
        label: "Metrics · 24h",
        systemImage: "checkmark.circle",
        value: format(viewModel.metricsCount),
        isLoading: viewModel.metricsCount == nil,
        deepLink: .insights
      ),
      CardData(
        id: "funnels_24h",
        label: "Funnels · 24h",
        systemImage: "line.3.horizontal.decrease.circle",
        value: funnelsValue,
        secondary: funnelsPercent,
        isLoading: viewModel.funnelsCompletedCount == nil,
        deepLink: .insights
      ),
      CardData(
        id: "avg_rating",
        label: "Avg Rating",
        systemImage: "star",
        value: avgRatingValue,
        secondary: avgRatingSecondary,
        isLoading: false,
        deepLink: .ratingsList
      )
    ]
  }

  private var ratingSummary: (avg: Double, total: Int)? {
    let scopedApps = appState.apps.filter {
      appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId
    }
    var weightedSum: Double = 0
    var total: Int = 0
    for app in scopedApps {
      guard let rating = app.worldwideAverageRating, let count = app.worldwideRatingCount, count > 0 else { continue }
      weightedSum += rating * Double(count)
      total += count
    }
    guard total > 0 else { return nil }
    return (weightedSum / Double(total), total)
  }

  private var avgRatingValue: String {
    guard let summary = ratingSummary else { return "—" }
    return String(format: "★ %.1f", summary.avg)
  }

  private var avgRatingSecondary: String? {
    guard let summary = ratingSummary else { return nil }
    return summary.total.formatted(.number)
  }

  private var funnelsValue: String {
    guard let completed = viewModel.funnelsCompletedCount else { return "—" }
    let started = viewModel.funnelsStartedCount ?? 0
    return "\(format(completed))/\(format(started))"
  }

  private var funnelsPercent: String? {
    guard let completed = viewModel.funnelsCompletedCount,
      let started = viewModel.funnelsStartedCount,
      started > 0
    else { return nil }
    let pct = Int((Double(completed) / Double(started) * 100).rounded())
    return "\(pct)%"
  }

  private func format(_ value: Int?) -> String {
    guard let value else { return "—" }
    return value.formatted(.number)
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    await viewModel.load(
      teamId: teamId,
      projectId: appState.selectedProjectId,
      dataMode: appState.dataMode
    )
  }

  private struct CardData: Identifiable {
    let id: String
    let label: String
    let systemImage: String
    let value: String
    var secondary: String? = nil
    let isLoading: Bool
    let deepLink: DeepLink
  }
}
