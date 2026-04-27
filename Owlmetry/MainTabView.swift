import SwiftUI
import UIKit

struct MainTabView: View {
  @State private var selection: Tab = .dashboard
  @State private var dashboardPath = NavigationPath()
  @State private var issuesPath = NavigationPath()
  @State private var feedbackPath = NavigationPath()
  @StateObject private var router = DeepLinkRouter.shared

  init() {
    let itemAppearance = UITabBarItemAppearance()
    let hiddenTitle: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.clear,
      .font: UIFont.systemFont(ofSize: 0.1)
    ]
    for state in [itemAppearance.normal, itemAppearance.selected, itemAppearance.focused, itemAppearance.disabled] {
      state.titleTextAttributes = hiddenTitle
      state.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 500)
    }

    let barAppearance = UITabBarAppearance()
    barAppearance.configureWithDefaultBackground()
    barAppearance.stackedLayoutAppearance = itemAppearance
    barAppearance.inlineLayoutAppearance = itemAppearance
    barAppearance.compactInlineLayoutAppearance = itemAppearance

    UITabBar.appearance().standardAppearance = barAppearance
    UITabBar.appearance().scrollEdgeAppearance = barAppearance
    UITabBarItem.appearance().imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
  }

  enum Tab: Hashable {
    case dashboard, issues, feedback, insights, users
  }

  var body: some View {
    TabView(selection: Binding(
      get: { selection },
      set: { newValue in
        if newValue != selection {
          Haptics.play(.light)
        }
        selection = newValue
      }
    )) {
      NavigationStack(path: $dashboardPath) {
        DashboardView()
          .navigationDestination(for: NotificationsDeepLinkRoute.self) { _ in
            NotificationsListView()
          }
      }
        .tabItem { Image(systemName: "house") }
        .tag(Tab.dashboard)

      NavigationStack(path: $issuesPath) {
        IssuesListView()
          .navigationDestination(for: IssueDeepLinkRoute.self) { route in
            IssueDetailLoaderView(projectId: route.projectId, issueId: route.id)
          }
      }
        .tabItem { Image(systemName: "ant") }
        .tag(Tab.issues)

      NavigationStack(path: $feedbackPath) {
        FeedbackHubView()
          .navigationDestination(for: FeedbackListNavRoute.self) { _ in
            FeedbackListView()
          }
          .navigationDestination(for: ReviewsListNavRoute.self) { _ in
            ReviewsListView()
          }
          .navigationDestination(for: RatingsListNavRoute.self) { _ in
            RatingsView()
          }
          .navigationDestination(for: FeedbackDeepLinkRoute.self) { route in
            FeedbackDetailLoaderView(projectId: route.projectId, feedbackId: route.id)
          }
      }
        .tabItem { Image(systemName: "bubble.left") }
        .tag(Tab.feedback)

      NavigationStack { InsightsView() }
        .tabItem { Image(systemName: "chart.xyaxis.line") }
        .tag(Tab.insights)

      NavigationStack { UsersListView() }
        .tabItem { Image(systemName: "person.2") }
        .tag(Tab.users)
    }
    .onChange(of: router.pendingDeepLink) { _, link in
      guard let link else { return }
      handle(link)
      router.pendingDeepLink = nil
    }
  }

  private func handle(_ link: DeepLink) {
    switch link {
    case .issue(let id, let projectId):
      selection = .issues
      issuesPath = NavigationPath()
      if let projectId {
        issuesPath.append(IssueDeepLinkRoute(id: id, projectId: projectId))
      }
      // No projectId — leave on the list. Server began including project_id
      // in `data` so this only happens for legacy in-flight pushes.
    case .feedback(let id, let projectId):
      selection = .feedback
      feedbackPath = NavigationPath()
      feedbackPath.append(FeedbackListNavRoute())
      if let projectId {
        feedbackPath.append(FeedbackDeepLinkRoute(id: id, projectId: projectId))
      }
    case .issuesList:
      selection = .issues
      issuesPath = NavigationPath()
    case .feedbackList:
      selection = .feedback
      feedbackPath = NavigationPath()
      feedbackPath.append(FeedbackListNavRoute())
    case .reviewsList:
      selection = .feedback
      feedbackPath = NavigationPath()
      feedbackPath.append(ReviewsListNavRoute())
    case .ratingsList:
      selection = .feedback
      feedbackPath = NavigationPath()
      feedbackPath.append(RatingsListNavRoute())
    case .usersList:
      selection = .users
    case .insights:
      selection = .insights
    case .notifications:
      selection = .dashboard
      dashboardPath = NavigationPath()
      dashboardPath.append(NotificationsDeepLinkRoute())
    case .unknown:
      break
    }
  }
}
