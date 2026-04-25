import SwiftUI
import UIKit

struct MainTabView: View {
  @State private var selection: Tab = .dashboard
  @State private var pendingIssueId: String?
  @State private var pendingFeedbackId: String?
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
      NavigationStack { DashboardView() }
        .tabItem { Image(systemName: "house") }
        .tag(Tab.dashboard)

      NavigationStack { IssuesListView() }
        .tabItem { Image(systemName: "ant") }
        .tag(Tab.issues)

      NavigationStack { FeedbackListView() }
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
      switch link {
      case .issue:
        selection = .issues
      case .feedback:
        selection = .feedback
      case .notifications:
        // Notifications are accessed via Profile from Dashboard
        selection = .dashboard
      case .unknown:
        break
      }
      // Clear after handling — the destination tab can read the original
      // link via the router if it needs the specific id.
      router.pendingDeepLink = nil
    }
  }
}
