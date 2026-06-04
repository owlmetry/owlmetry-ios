import Foundation

/// One card's rendered values — already formatted into the strings `StatCard`
/// expects, so the app and the widget display identical text.
struct MetricValue: Equatable, Codable {
  let value: String          // big number, e.g. "1,234", "12/24", "★ 4.52", or "—"
  let secondary: String?     // percent or count shown next to the value
  let delta: Int?            // change indicator (reviews use 24h new-count)
  let sparkline: [Double]    // 30-day series; empty for count-only metrics

  init(value: String, secondary: String? = nil, delta: Int? = nil, sparkline: [Double] = []) {
    self.value = value
    self.secondary = secondary
    self.delta = delta
    self.sparkline = sparkline
  }

  /// Placeholder shown while loading or when a fetch fails.
  static let dash = MetricValue(value: "—")
}

/// A loaded set of metric values plus when it was produced (for "updated N ago").
struct DashboardSnapshot {
  var values: [DashboardMetric: MetricValue]
  let generatedAt: Date

  func value(for metric: DashboardMetric) -> MetricValue {
    values[metric] ?? .dash
  }
}
