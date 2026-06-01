import Foundation

/// The dashboard magnitude-tile time window (the "· 24h" count window on
/// Events/Users/Sessions/Metrics/Funnels/Responses). Mirrors the web
/// `@owlmetry/shared/preferences` MAGNITUDE_WINDOW_HOURS family — kept local
/// because iOS doesn't pull from the npm package; the server validates inputs.
///
/// The chosen value persists server-side under
/// `users.preferences.ui.dashboard.magnitudeWindowHours` (shared with the web
/// dashboard) and is mirrored locally in `UserDefaults` for an instant/offline
/// value on launch.
enum MagnitudeWindow {
  /// 1h / 24h / 7d / 30d, expressed in hours.
  static let optionsHours = [1, 24, 168, 720]
  static let defaultHours = 24

  /// Clamp an arbitrary stored value to a supported option (falls back to 24h).
  static func resolve(_ raw: Int?) -> Int {
    guard let raw, optionsHours.contains(raw) else { return defaultHours }
    return raw
  }

  /// "1h" / "24h" / "7d" / "30d" — mirrors web `formatMagnitudeWindowLabel`.
  static func label(_ hours: Int) -> String {
    hours > 24 && hours % 24 == 0 ? "\(hours / 24)d" : "\(hours)h"
  }
}
