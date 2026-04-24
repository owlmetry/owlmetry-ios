import Combine
import Foundation

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
    } catch let error as APIError {
      errorMessage = error.errorDescription
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func verifyCode(_ code: String) async {
    guard let email = pendingEmail else {
      errorMessage = "Please enter your email first."
      return
    }

    let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count == 6 else {
      errorMessage = "Enter the 6-digit code from your email."
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
    } catch let error as APIError {
      errorMessage = error.errorDescription
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func logout() {
    KeychainService.deleteToken()
    UserDefaults.standard.removeObject(forKey: userCacheKey)
    UserDefaults.standard.removeObject(forKey: teamsCacheKey)
    currentUser = nil
    teams = []
    pendingEmail = nil
    errorMessage = nil
  }

  func clearPendingEmail() {
    pendingEmail = nil
  }

  private func restoreSession() {
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
