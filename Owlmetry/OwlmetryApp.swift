import SwiftUI

@main
struct OwlmetryApp: App {
  @StateObject private var auth = AuthViewModel.shared

  var body: some Scene {
    WindowGroup {
      Group {
        if let user = auth.currentUser {
          HomeView(user: user)
        } else {
          OnboardingView()
        }
      }
      .environmentObject(auth)
    }
  }
}
