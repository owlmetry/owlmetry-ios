import Foundation

/// Persists the last-good dashboard metric values per scope so a cold launch can
/// render real numbers instantly instead of a wall of per-card spinners. App-only
/// (`UserDefaults.standard`) — the widget loads its own snapshot independently.
///
/// Keyed by the same scope string the dashboard builds
/// (`"<teamId>|<projectId>|<dataMode>|<windowHours>"`), so switching project /
/// data-mode / window restores that scope's cached values rather than the previous
/// scope's stale numbers.
enum DashboardCache {
  /// One scope's cached values. `DashboardMetric` is `String`-backed but not
  /// `Codable`, so values are stored under their rawValue keys and remapped at the
  /// boundary.
  private struct CachedDashboardSnapshot: Codable {
    let values: [String: MetricValue]
    let generatedAt: Date
  }

  private static let storageKey = "dashboard:cache:v1"

  /// Cap the number of retained scopes so the blob stays small as team / project /
  /// data-mode / window combinations accumulate over time.
  private static let maxScopes = 12

  static func load(scope: String) -> (values: [DashboardMetric: MetricValue], generatedAt: Date)? {
    guard let entry = readAll()[scope] else { return nil }
    var remapped: [DashboardMetric: MetricValue] = [:]
    for (rawKey, value) in entry.values {
      if let metric = DashboardMetric(rawValue: rawKey) {
        remapped[metric] = value
      }
    }
    return (remapped, entry.generatedAt)
  }

  static func save(scope: String, values: [DashboardMetric: MetricValue], generatedAt: Date) {
    var all = readAll()
    var stored: [String: MetricValue] = [:]
    for (metric, value) in values {
      stored[metric.rawValue] = value
    }
    all[scope] = CachedDashboardSnapshot(values: stored, generatedAt: generatedAt)

    // Keep only the most recently generated scopes.
    if all.count > maxScopes {
      let survivors = all.sorted { $0.value.generatedAt > $1.value.generatedAt }.prefix(maxScopes)
      all = Dictionary(uniqueKeysWithValues: survivors.map { ($0.key, $0.value) })
    }

    guard let data = try? JSONEncoder().encode(all) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }

  private static func readAll() -> [String: CachedDashboardSnapshot] {
    guard
      let data = UserDefaults.standard.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode([String: CachedDashboardSnapshot].self, from: data)
    else { return [:] }
    return decoded
  }
}
