import Combine
import Foundation
import Owlmetry

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var currentTeam: TeamMembership?
  @Published var selectedProjectId: String?
  @Published var dataMode: DataMode = .production
  @Published private(set) var projects: [Project] = []
  @Published private(set) var projectsById: [String: Project] = [:]
  @Published private(set) var apps: [AppModel] = []
  @Published private(set) var isLoadingProjects = false
  @Published var loadError: String?

  init() {
    restoreDataMode()
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
    }
  }

  func setCurrentTeam(_ team: TeamMembership, restoreSelection: Bool = true) {
    currentTeam = team
    UserDefaults.standard.set(team.id, forKey: UserDefaultsKeys.currentTeam)
    if restoreSelection {
      restoreSelectedProject(for: team.id)
    } else {
      selectedProjectId = nil
    }
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
    Owl.info("appstate.data_mode.changed", attributes: ["mode": mode.rawValue])
  }

  func reset() {
    currentTeam = nil
    selectedProjectId = nil
    projects = []
    projectsById = [:]
    apps = []
    loadError = nil
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
      if let selected = selectedProjectId, projectsById[selected] == nil {
        selectedProjectId = nil
      }
    } catch let error as APIError {
      loadError = error.errorDescription
      Owl.error("appstate.load_projects_and_apps.failed", attributes: ["error": "\(error)"])
    } catch {
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
}
