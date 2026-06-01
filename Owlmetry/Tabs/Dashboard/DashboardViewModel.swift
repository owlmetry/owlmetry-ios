import Combine
import Foundation
import Owlmetry

@MainActor
final class DashboardViewModel: ObservableObject {
  /// Latest merged metric values. Merged (not replaced) so a transient failure
  /// on one metric keeps its last good value rather than flashing "—" during
  /// the 30s polling cadence. Avg Rating is layered on by the View from
  /// `appState.apps` (project-scoped, no fetch) — it's not requested here.
  @Published private(set) var values: [DashboardMetric: MetricValue] = [:]
  @Published var lastUpdatedAt: Date?
  @Published var errorMessage: String?

  func value(for metric: DashboardMetric) -> MetricValue {
    values[metric] ?? .dash
  }

  /// True until the first successful value for `metric` lands (drives the
  /// per-card spinner).
  func isLoading(_ metric: DashboardMetric) -> Bool {
    values[metric] == nil
  }

  // All metrics the dashboard fetches over the network. Avg Rating is excluded
  // — the View computes it locally from already-loaded apps.
  private static let fetchedMetrics: Set<DashboardMetric> = [
    .openIssues, .events, .users, .sessions, .metrics, .funnels,
    .feedback, .responses, .reviews,
  ]

  // Sparklines describe a multi-day trend, so re-fetching at the 30s
  // count-card cadence is overkill. Match the web hook's `5 * 60_000`
  // SWR refreshInterval. Scope change (team / project / data mode)
  // forces a refresh regardless.
  private static let sparklineMaxAgeSeconds: TimeInterval = 5 * 60
  private var lastSparklineLoadAt: Date?
  private var lastSparklineScope: String?

  func load(teamId: String, projectId: String?, dataMode: DataMode, windowHours: Int) async {
    let scope = "\(teamId)|\(projectId ?? "-")|\(dataMode.rawValue)|\(windowHours)"
    let includeSparklines = shouldRefreshSparklines(scope: scope)

    let snapshot = await DashboardSnapshotLoader.load(
      teamId: teamId,
      projectId: projectId,
      dataMode: dataMode,
      metrics: Self.fetchedMetrics,
      includeSparklines: includeSparklines,
      windowHours: windowHours
    )

    if Task.isCancelled { return }

    // A scope with zero successful metrics and no prior data is a hard failure;
    // otherwise merge so last-good values persist and stale sparklines survive
    // a count-only refresh.
    let gotAnything = !snapshot.values.isEmpty
    if gotAnything {
      merge(snapshot.values, refreshedSparklines: includeSparklines)
      if includeSparklines {
        lastSparklineLoadAt = Date()
        lastSparklineScope = scope
      }
    }

    if !gotAnything && values.isEmpty {
      errorMessage = "Couldn't load dashboard. Pull to retry."
    } else {
      errorMessage = nil
      lastUpdatedAt = Date()
    }
  }

  private func shouldRefreshSparklines(scope: String) -> Bool {
    let scopeChanged = scope != lastSparklineScope
    let isStale = lastSparklineLoadAt.map {
      Date().timeIntervalSince($0) > Self.sparklineMaxAgeSeconds
    } ?? true
    return scopeChanged || isStale
  }

  /// Overwrite each freshly-loaded metric. When sparklines were *not* refreshed
  /// this round, carry the prior series forward onto the new (count-only) value
  /// so the chart doesn't blank between the 5-min sparkline refreshes.
  private func merge(_ incoming: [DashboardMetric: MetricValue], refreshedSparklines: Bool) {
    for (metric, newValue) in incoming {
      if !refreshedSparklines, metric.hasSparkline, let prior = values[metric], !prior.sparkline.isEmpty {
        values[metric] = MetricValue(
          value: newValue.value,
          secondary: newValue.secondary,
          delta: newValue.delta,
          sparkline: prior.sparkline
        )
      } else {
        values[metric] = newValue
      }
    }
  }
}
