import Owlmetry
import SwiftUI

@main
struct OwlmetryApp: App {
  @StateObject private var auth = AuthViewModel.shared
  @StateObject private var appState = AppState()

  init() {
    do {
      try Owl.configure(
        endpoint: OwlmetrySecrets.endpoint,
        apiKey: OwlmetrySecrets.clientKey
      )
    } catch {
      print("Owlmetry configure failed: \(error)")
    }
    if let id = AuthViewModel.shared.currentUser?.id {
      Owl.setUser(id)
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(auth)
        .environmentObject(appState)
    }
  }
}
