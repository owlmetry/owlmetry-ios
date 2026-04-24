import Foundation

enum UserDefaultsKeys {
  static let currentTeam = "owlmetry:current-team"
  static let dataMode = "owlmetry:data-mode"
  static func lastProject(teamId: String) -> String {
    "owlmetry:last-project:\(teamId)"
  }
}
