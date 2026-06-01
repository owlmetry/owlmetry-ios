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
          ForEach(orderedMetrics, id: \.self) { metric in
            let card = cardData(for: metric)
            Button {
              Haptics.play(.light)
              DeepLinkRouter.shared.pendingDeepLink = deepLink(for: metric)
            } label: {
              StatCard(
                label: metric.label(windowHours: appState.magnitudeWindowHours),
                systemImage: metric.systemImage,
                value: card.value,
                secondary: card.secondary,
                delta: card.delta,
                isLoading: card.isLoading,
                sparklineValues: metric.hasSparkline ? card.sparkline : nil
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
    return "\(team)|\(proj)|\(appState.dataMode.rawValue)|\(appState.magnitudeWindowHours)"
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

  // Dashboard card order (matches the web + iOS dashboard layout).
  private let orderedMetrics: [DashboardMetric] = [
    .openIssues, .events, .users, .sessions, .metrics, .funnels,
    .feedback, .responses, .reviews, .avgRating,
  ]

  /// The rendered value for a card. Network metrics come from the VM snapshot;
  /// Avg Rating is computed locally from already-loaded, project-scoped apps
  /// (no extra fetch, updates live as apps load).
  private func cardData(for metric: DashboardMetric) -> (value: String, secondary: String?, delta: Int?, sparkline: [Double], isLoading: Bool) {
    if metric == .avgRating {
      let v = avgRatingValue
      return (v.value, v.secondary, v.delta, [], false)
    }
    let v = viewModel.value(for: metric)
    return (v.value, v.secondary, v.delta, v.sparkline, viewModel.isLoading(metric))
  }

  /// Avg Rating uses the in-memory apps the app already loaded, scoped to the
  /// selected project — no service call, unlike the other (fetched) cards.
  private var avgRatingValue: MetricValue {
    let scopedApps = appState.apps.filter {
      appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId
    }
    return DashboardSnapshotLoader.avgRatingValue(scopedApps)
  }

  // The dashboard's deep links keep their richer project-aware forms; the
  // shared `DashboardMetric.deepLinkPath` (string form) is only for widget URLs.
  private func deepLink(for metric: DashboardMetric) -> DeepLink {
    switch metric {
    case .openIssues: return .issuesList(projectId: nil)
    case .events, .users, .sessions: return .usersList
    case .metrics, .funnels: return .insights
    case .feedback: return .feedbackList(projectId: nil)
    case .responses: return .questionnairesList
    case .reviews: return .reviewsList
    case .avgRating: return .ratingsList
    }
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    await viewModel.load(
      teamId: teamId,
      projectId: appState.selectedProjectId,
      dataMode: appState.dataMode,
      windowHours: appState.magnitudeWindowHours
    )
  }
}
