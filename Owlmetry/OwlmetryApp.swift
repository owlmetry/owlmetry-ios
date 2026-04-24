import SwiftUI

@main
struct OwlmetryApp: App {
  @StateObject private var auth = AuthViewModel.shared
  @StateObject private var appState = AppState()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(auth)
        .environmentObject(appState)
    }
  }
}
