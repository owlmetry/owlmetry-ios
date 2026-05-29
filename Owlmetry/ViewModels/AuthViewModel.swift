import Combine
import Foundation
import Owlmetry
import WidgetKit

@MainActor
class AuthViewModel: ObservableObject {
  public static let shared = AuthViewModel()

  @Published private(set) var currentUser: User?
  @Published private(set) var teams: [TeamMembership] = []
  @Published private(set) var isLoading = false
  @Published var errorMessage: String?
  @Published private(set) var pendingEmail: String?

  private let userCacheKey = "auth.cachedUser"
  private let teamsCacheKey = "auth.cachedTeams"

  var isSignedIn: Bool { currentUser != nil }

  private init() {
    restoreSession()
  }

  func sendCode(email: String) async {
    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      errorMessage = "Please enter your email."
      Owl.warn("auth.email.invalid", screenName: "SignInEmail")
      return
    }

    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      let _: SendCodeResponse = try await APIClient.shared.post(
        "/v1/auth/send-code",
        body: SendCodeRequest(email: trimmed)
      )
      pendingEmail = trimmed
      Owl.info("auth.send_code.succeeded", screenName: "SignInEmail")
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Owl.error("auth.send_code.failed", screenName: "SignInEmail", attributes: ["error": "\(error)"])
    } catch {
      errorMessage = error.localizedDescription
      Owl.error("auth.send_code.failed", screenName: "SignInEmail", attributes: ["error": "\(error)"])
    }
  }

  func verifyCode(_ code: String) async {
    guard let email = pendingEmail else {
      errorMessage = "Please enter your email first."
      Owl.warn("auth.code.no_pending_email", screenName: "SignInCode")
      return
    }

    let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count == 6 else {
      errorMessage = "Enter the 6-digit code from your email."
      Owl.warn("auth.code.invalid", screenName: "SignInCode", attributes: ["length": "\(trimmed.count)"])
      return
    }

    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      let response: VerifyCodeResponse = try await APIClient.shared.post(
        "/v1/auth/verify-code",
        body: VerifyCodeRequest(email: email, code: trimmed)
      )
      KeychainService.saveToken(response.token)
      cacheUser(response.user, teams: response.teams)
      currentUser = response.user
      teams = response.teams
      pendingEmail = nil
      Owl.setUser(response.user.id)
      // Token now lives in the shared Keychain group — refresh widgets so they
      // flip from the signed-out placeholder to live numbers.
      WidgetCenter.shared.reloadAllTimelines()
      Owl.info("auth.login.succeeded", screenName: "SignInCode")
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Owl.error("auth.verify_code.failed", screenName: "SignInCode", attributes: ["error": "\(error)"])
    } catch {
      errorMessage = error.localizedDescription
      Owl.error("auth.verify_code.failed", screenName: "SignInCode", attributes: ["error": "\(error)"])
    }
  }

  func logout() {
    Owl.info("auth.logout")
    Owl.clearUser()
    KeychainService.deleteToken()
    UserDefaults.standard.removeObject(forKey: userCacheKey)
    UserDefaults.standard.removeObject(forKey: teamsCacheKey)
    currentUser = nil
    teams = []
    pendingEmail = nil
    errorMessage = nil
    // Token is gone — widgets should fall back to the signed-out placeholder.
    WidgetCenter.shared.reloadAllTimelines()
  }

  func clearPendingEmail() {
    pendingEmail = nil
  }

  private func restoreSession() {
    // Move any pre-sharing token into the shared Keychain group before the
    // first read, so existing users stay signed in (and the widget can read
    // the token) on the first launch after this update.
    KeychainService.migrateToSharedGroupIfNeeded()
    guard KeychainService.token() != nil else { return }
    if let userData = UserDefaults.standard.data(forKey: userCacheKey),
       let user = try? JSONDecoder().decode(User.self, from: userData) {
      currentUser = user
    }
    if let teamsData = UserDefaults.standard.data(forKey: teamsCacheKey),
       let cachedTeams = try? JSONDecoder().decode([TeamMembership].self, from: teamsData) {
      teams = cachedTeams
    }
  }

  private func cacheUser(_ user: User, teams: [TeamMembership]) {
    if let userData = try? JSONEncoder().encode(user) {
      UserDefaults.standard.set(userData, forKey: userCacheKey)
    }
    if let teamsData = try? JSONEncoder().encode(teams) {
      UserDefaults.standard.set(teamsData, forKey: teamsCacheKey)
    }
  }
}
