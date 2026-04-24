import SwiftUI

struct MainTabView: View {
  @State private var selection: Tab = .dashboard

  enum Tab: Hashable {
    case dashboard, issues, feedback, metrics, funnels, users
  }

  var body: some View {
    TabView(selection: $selection) {
      NavigationStack { DashboardView() }
        .tabItem { Label("Dashboard", systemImage: "house") }
        .tag(Tab.dashboard)

      NavigationStack { IssuesListView() }
        .tabItem { Label("Issues", systemImage: "ant") }
        .tag(Tab.issues)

      NavigationStack { FeedbackListView() }
        .tabItem { Label("Feedback", systemImage: "bubble.left") }
        .tag(Tab.feedback)

      NavigationStack { MetricsListView() }
        .tabItem { Label("Metrics", systemImage: "chart.bar") }
        .tag(Tab.metrics)

      NavigationStack { FunnelsListView() }
        .tabItem { Label("Funnels", systemImage: "line.3.horizontal.decrease.circle") }
        .tag(Tab.funnels)

      NavigationStack { UsersListView() }
        .tabItem { Label("Users", systemImage: "person.2") }
        .tag(Tab.users)
    }
  }
}
