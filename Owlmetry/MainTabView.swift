import SwiftUI
import UIKit

struct MainTabView: View {
  @State private var selection: Tab = .dashboard

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
    TabView(selection: $selection) {
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
  }
}
