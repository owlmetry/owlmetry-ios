import Foundation

/// Cross-process bridge between the app and the widget extension. The app
/// mirror-writes the current scope here whenever it changes; the widget reads
/// it to know which team/data-mode to query. Backed by the shared App Group
/// container so both processes see the same values.
///
/// The auth token itself is NOT here — it lives in the shared Keychain group
/// (see `KeychainService`). This store is only non-secret context.
enum WidgetSharedStore {
  static let suiteName = "group.com.Owlmetry"

  /// `nil` only if the App Group entitlement is missing/misconfigured — callers
  /// degrade gracefully (app keeps working off `UserDefaults.standard`; widget
  /// falls back to defaults).
  static var suite: UserDefaults? { UserDefaults(suiteName: suiteName) }

  private enum Keys {
    static let teamId = "widget:teamId"
    static let dataMode = "widget:dataMode"
    static let magnitudeWindow = "widget:magnitudeWindow"
    static let baseURLOverride = "widget:baseURLOverride"
  }

  /// Widgets are team-scoped (all projects). Persist the current team + data
  /// mode + dashboard stat window so the timeline provider resolves the same
  /// scope the app shows.
  static func writeContext(teamId: String?, dataMode: DataMode, magnitudeWindowHours: Int) {
    guard let suite else { return }
    if let teamId {
      suite.set(teamId, forKey: Keys.teamId)
    } else {
      suite.removeObject(forKey: Keys.teamId)
    }
    suite.set(dataMode.rawValue, forKey: Keys.dataMode)
    suite.set(magnitudeWindowHours, forKey: Keys.magnitudeWindow)
  }

  static var teamId: String? { suite?.string(forKey: Keys.teamId) }

  static var dataMode: DataMode {
    suite?.string(forKey: Keys.dataMode).flatMap(DataMode.init(rawValue:)) ?? .production
  }

  /// The dashboard magnitude window the widget should query + label with.
  /// Defaults to 24h before the app has written any context.
  static var magnitudeWindowHours: Int {
    MagnitudeWindow.resolve(suite?.object(forKey: Keys.magnitudeWindow) as? Int)
  }

  /// Mirrors the dev-only API base-URL override so a non-prod widget hits the
  /// same backend as the app. Nil/empty clears it.
  static var baseURLOverride: String? {
    get { suite?.string(forKey: Keys.baseURLOverride) }
    set {
      guard let suite else { return }
      if let value = newValue, !value.isEmpty {
        suite.set(value, forKey: Keys.baseURLOverride)
      } else {
        suite.removeObject(forKey: Keys.baseURLOverride)
      }
    }
  }
}
