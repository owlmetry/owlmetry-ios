import Combine
import Foundation
import Owlmetry
import WidgetKit

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var currentTeam: TeamMembership?
  @Published var selectedProjectId: String?
  @Published var dataMode: DataMode = .production
  /// Dashboard magnitude-tile window (hours). Synced with the web dashboard via
  /// `users.preferences.ui.dashboard.magnitudeWindowHours`; the `UserDefaults`
  /// mirror gives an instant/offline value before the server fetch resolves.
  @Published var magnitudeWindowHours: Int = MagnitudeWindow.defaultHours
  @Published private(set) var projects: [Project] = []
  @Published private(set) var projectsById: [String: Project] = [:]
  @Published private(set) var apps: [AppModel] = []
  @Published private(set) var isLoadingProjects = false
  @Published var loadError: String?

  init() {
    restoreDataMode()
    restoreMagnitudeWindow()
  }

  var selectedProject: Project? {
    guard let id = selectedProjectId else { return nil }
    return projectsById[id]
  }

  var projectsForCurrentTeam: [Project] {
    guard let teamId = currentTeam?.id else { return [] }
    return projects.filter { $0.teamId == teamId }
  }

  func configure(with teams: [TeamMembership]) {
    if let stored = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentTeam),
       let match = teams.first(where: { $0.id == stored }) {
      setCurrentTeam(match, restoreSelection: true)
    } else if let first = teams.first {
      setCurrentTeam(first, restoreSelection: true)
    } else {
      currentTeam = nil
      selectedProjectId = nil
      syncWidgetContext()
    }
    // Adopt the server's dashboard window once per session (server wins over the
    // local mirror on launch/login). Runs after the token is established.
    Task { await syncMagnitudeWindowFromServer() }
  }

  func setCurrentTeam(_ team: TeamMembership, restoreSelection: Bool = true) {
    currentTeam = team
    UserDefaults.standard.set(team.id, forKey: UserDefaultsKeys.currentTeam)
    if restoreSelection {
      restoreSelectedProject(for: team.id)
    } else {
      selectedProjectId = nil
    }
    syncWidgetContext()
  }

  func setSelectedProject(_ id: String?) {
    selectedProjectId = id
    guard let teamId = currentTeam?.id else { return }
    let key = UserDefaultsKeys.lastProject(teamId: teamId)
    if let id {
      UserDefaults.standard.set(id, forKey: key)
    } else {
      UserDefaults.standard.removeObject(forKey: key)
    }
    Owl.info("appstate.project.switched", attributes: ["project_id": id ?? "all"])
  }

  func setDataMode(_ mode: DataMode) {
    dataMode = mode
    UserDefaults.standard.set(mode.rawValue, forKey: UserDefaultsKeys.dataMode)
    syncWidgetContext()
    Owl.info("appstate.data_mode.changed", attributes: ["mode": mode.rawValue])
  }

  /// Set the dashboard magnitude window. Optimistic: updates the published value
  /// and the local mirror immediately (so the dashboard re-scopes at once and
  /// the choice survives offline), then persists to the server preferences so it
  /// syncs with the web dashboard. A failed PATCH keeps the local value — the
  /// mirror is the source of truth offline and the next launch re-syncs.
  func setMagnitudeWindow(_ hours: Int) {
    let resolved = MagnitudeWindow.resolve(hours)
    magnitudeWindowHours = resolved
    UserDefaults.standard.set(resolved, forKey: UserDefaultsKeys.magnitudeWindow)
    Owl.info("appstate.magnitude_window.changed", attributes: ["hours": "\(resolved)"])
    Task {
      do {
        let patch = MagnitudeWindowPatch(
          preferences: .init(ui: .init(dashboard: .init(magnitudeWindowHours: resolved)))
        )
        // Send WITHOUT snake-case conversion — the server JSONB key is literally
        // `magnitudeWindowHours`; snake-casing it makes the sanitizer drop it.
        let _: MeEnvelope = try await APIClient.shared.patch(
          "/v1/auth/me", body: patch, convertKeysToSnakeCase: false
        )
      } catch {
        Owl.error("appstate.magnitude_window.patch_failed", attributes: ["error": "\(error)"])
      }
    }
  }

  /// Adopt the server-side dashboard window if present. Best-effort: a failure
  /// leaves the local mirror value in place.
  func syncMagnitudeWindowFromServer() async {
    do {
      let me: MeEnvelope = try await APIClient.shared.get("/v1/auth/me")
      guard let stored = me.user.preferences?.ui?.dashboard?.magnitudeWindowHours else { return }
      let resolved = MagnitudeWindow.resolve(stored)
      magnitudeWindowHours = resolved
      UserDefaults.standard.set(resolved, forKey: UserDefaultsKeys.magnitudeWindow)
    } catch {
      if error.isCancellation { return }
      Owl.error("appstate.magnitude_window.sync_failed", attributes: ["error": "\(error)"])
    }
  }

  func reset() {
    currentTeam = nil
    selectedProjectId = nil
    projects = []
    projectsById = [:]
    apps = []
    loadError = nil
    syncWidgetContext()
  }

  /// Mirror the current team + data mode into the shared App Group container so
  /// the widget extension queries the same scope. Widgets are team-total, so
  /// only the team id and data mode matter (no project).
  private func syncWidgetContext() {
    WidgetSharedStore.writeContext(teamId: currentTeam?.id, dataMode: dataMode)
    WidgetCenter.shared.reloadAllTimelines()
  }

  func loadProjectsAndApps() async {
    guard let teamId = currentTeam?.id else { return }
    isLoadingProjects = true
    defer { isLoadingProjects = false }
    loadError = nil
    do {
      async let projectsDTO: ProjectsListDTO = APIClient.shared.get(
        "/v1/projects",
        query: ["team_id": teamId]
      )
      async let appsDTO: AppsListDTO = APIClient.shared.get(
        "/v1/apps",
        query: ["team_id": teamId]
      )
      let (projects, apps) = try await (projectsDTO, appsDTO)
      self.projects = projects.projects
      self.projectsById = Dictionary(uniqueKeysWithValues: projects.projects.map { ($0.id, $0) })
      self.apps = apps.apps
      let teamProjects = projects.projects.filter { $0.teamId == teamId }
      if teamProjects.count == 1 {
        selectedProjectId = teamProjects[0].id
      } else if let selected = selectedProjectId, projectsById[selected] == nil {
        selectedProjectId = nil
      }
    } catch let error as APIError {
      loadError = error.errorDescription
      Owl.error("appstate.load_projects_and_apps.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      loadError = error.localizedDescription
      Owl.error("appstate.load_projects_and_apps.failed", attributes: ["error": "\(error)"])
    }
  }

  private func restoreSelectedProject(for teamId: String) {
    let key = UserDefaultsKeys.lastProject(teamId: teamId)
    selectedProjectId = UserDefaults.standard.string(forKey: key)
  }

  private func restoreDataMode() {
    if let raw = UserDefaults.standard.string(forKey: UserDefaultsKeys.dataMode),
       let mode = DataMode(rawValue: raw) {
      dataMode = mode
    }
  }

  private func restoreMagnitudeWindow() {
    let stored = UserDefaults.standard.object(forKey: UserDefaultsKeys.magnitudeWindow) as? Int
    magnitudeWindowHours = MagnitudeWindow.resolve(stored)
  }
}

// MARK: - /v1/auth/me preference shapes (dashboard window slice only)

/// Decodes just the `ui.dashboard.magnitudeWindowHours` slice of the auth/me
/// response — other preference keys are ignored. Decoded with the shared
/// `.convertFromSnakeCase` decoder, which is a no-op on the already-camelCase
/// `magnitudeWindowHours` key (no underscores), so it round-trips correctly.
private struct MeEnvelope: Decodable {
  let user: UserSlice
  struct UserSlice: Decodable { let preferences: Prefs? }
  struct Prefs: Decodable { let ui: UI? }
  struct UI: Decodable { let dashboard: Dashboard? }
  struct Dashboard: Decodable { let magnitudeWindowHours: Int? }
}

/// PATCH body for the dashboard window. Sent with `convertKeysToSnakeCase: false`
/// so `magnitudeWindowHours` reaches the wire verbatim (the server JSONB key is
/// camelCase; snake-casing it would make the sanitizer silently drop it).
private struct MagnitudeWindowPatch: Encodable {
  let preferences: Prefs
  struct Prefs: Encodable { let ui: UI }
  struct UI: Encodable { let dashboard: Dashboard }
  struct Dashboard: Encodable { let magnitudeWindowHours: Int }
}
