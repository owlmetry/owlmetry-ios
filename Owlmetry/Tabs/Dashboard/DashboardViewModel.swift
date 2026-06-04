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

  /// True while a network refresh is in flight. Drives the single indicator next
  /// to the "Updated N ago" label so cached cards can show instantly without a
  /// spinner on every card.
  @Published private(set) var isRefreshing = false

  /// The scope of the values currently in `values`. When the next `load` targets
  /// a different scope we swap in that scope's cached values (or empty) instead of
  /// lingering on the previous scope's numbers.
  private var loadedScope: String?

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

    // On a scope change (including the cold-start first call, where `loadedScope`
    // is nil) restore that scope's cached values so cards render instantly instead
    // of flashing the previous scope's numbers or a wall of spinners. `lastUpdatedAt`
    // takes the cached timestamp so "Updated N ago" honestly shows the cache age
    // while the fresh fetch runs.
    if scope != loadedScope {
      if let cached = DashboardCache.load(scope: scope) {
        values = cached.values
        lastUpdatedAt = cached.generatedAt
      } else {
        values = [:]
        lastUpdatedAt = nil
      }
      loadedScope = scope
    }

    let includeSparklines = shouldRefreshSparklines(scope: scope)
    isRefreshing = true

    let snapshot = await DashboardSnapshotLoader.load(
      teamId: teamId,
      projectId: projectId,
      dataMode: dataMode,
      metrics: Self.fetchedMetrics,
      includeSparklines: includeSparklines,
      windowHours: windowHours
    )

    if Task.isCancelled {
      isRefreshing = false
      return
    }

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
      let now = Date()
      lastUpdatedAt = now
      // Persist the freshly-merged values (incl. carried-forward sparklines) so the
      // next cold launch of this scope renders instantly.
      DashboardCache.save(scope: scope, values: values, generatedAt: now)
    }

    isRefreshing = false
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
