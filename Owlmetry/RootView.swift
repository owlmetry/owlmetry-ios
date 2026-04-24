import SwiftUI

struct RootView: View {
  @EnvironmentObject private var auth: AuthViewModel
  @EnvironmentObject private var appState: AppState

  var body: some View {
    Group {
      if auth.currentUser != nil {
        MainTabView()
          .task(id: appState.currentTeam?.id) {
            await appState.loadProjectsAndApps()
          }
          .onAppear {
            if appState.currentTeam == nil {
              appState.configure(with: auth.teams)
            }
          }
          .onChange(of: auth.teams) { _, teams in
            appState.configure(with: teams)
          }
      } else {
        OnboardingView()
      }
    }
  }
}
