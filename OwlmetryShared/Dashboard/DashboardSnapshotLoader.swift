import Foundation

/// Fetches the dashboard metric values for a given scope, reusing the same
/// services the app's `DashboardViewModel` uses. Both the app dashboard and the
/// widget timeline providers call this so endpoints + formatting live in one
/// place.
///
/// A metric is present in the returned snapshot **only if its underlying fetch
/// succeeded** — a failed fetch leaves the metric absent rather than rendering
/// "—". This lets the dashboard VM preserve the last good value across its 30s
/// polls (merge: absent ⇒ keep prior), while widgets fall back to `.dash`.
///
/// `projectId` nil = team total (widgets always pass nil; the dashboard passes
/// its selected project). MainActor-isolated to match the services (the HTTP
/// still overlaps — URLSession suspends off the main actor).
@MainActor
enum DashboardSnapshotLoader {
  static func load(
    teamId: String,
    projectId: String?,
    dataMode: DataMode,
    metrics: Set<DashboardMetric>,
    includeSparklines: Bool,
    windowHours: Int = MagnitudeWindow.defaultHours
  ) async -> DashboardSnapshot {
    // Magnitude tiles use the selected window; sparklines stay 30-day (below).
    // The widget omits `windowHours`, keeping its fixed 24h team-total snapshot.
    let since = ISODate.isoString(since: TimeInterval(windowHours) * 3_600)
    let wantSpark = { (m: DashboardMetric) in includeSparklines && metrics.contains(m) }

    // Count fetches — each helper no-ops to nil when its metric isn't requested.
    async let events = fetchEvents(
      teamId: teamId, projectId: projectId, dataMode: dataMode, since: since,
      want: !metrics.isDisjoint(with: [.events, .users, .sessions])
    )
    async let issues = fetchOpenIssues(teamId: teamId, projectId: projectId, dataMode: dataMode, want: metrics.contains(.openIssues))
    async let metricsRes = fetchMetrics(teamId: teamId, projectId: projectId, dataMode: dataMode, since: since, want: metrics.contains(.metrics))
    async let funnelsRes = fetchFunnels(teamId: teamId, projectId: projectId, dataMode: dataMode, since: since, want: metrics.contains(.funnels))
    async let feedback = fetchFeedback(teamId: teamId, projectId: projectId, dataMode: dataMode, want: metrics.contains(.feedback))
    async let responses = fetchResponses(teamId: teamId, projectId: projectId, dataMode: dataMode, since: since, want: metrics.contains(.responses))
    async let reviews = fetchReviews(teamId: teamId, projectId: projectId, since: nil, want: metrics.contains(.reviews))
    async let reviewsDelta = fetchReviews(teamId: teamId, projectId: projectId, since: since, want: metrics.contains(.reviews))
    async let apps = fetchApps(teamId: teamId, projectId: projectId, want: metrics.contains(.avgRating))

    // Sparklines — one call per kind.
    async let eventsSpark = fetchSparkline(.events, teamId: teamId, projectId: projectId, dataMode: dataMode, want: wantSpark(.events))
    async let usersSpark = fetchSparkline(.users, teamId: teamId, projectId: projectId, dataMode: dataMode, want: wantSpark(.users))
    async let sessionsSpark = fetchSparkline(.sessions, teamId: teamId, projectId: projectId, dataMode: dataMode, want: wantSpark(.sessions))
    async let metricsSpark = fetchSparkline(.metricCompletions, teamId: teamId, projectId: projectId, dataMode: dataMode, want: wantSpark(.metrics))
    async let funnelsSpark = fetchSparkline(.funnelCompletions, teamId: teamId, projectId: projectId, dataMode: dataMode, want: wantSpark(.funnels))
    async let responsesSpark = fetchSparkline(.questionnaireResponses, teamId: teamId, projectId: projectId, dataMode: dataMode, want: wantSpark(.responses))

    let eventsResult = await events
    let issuesResult = await issues
    let metricsResult = await metricsRes
    let funnelsResult = await funnelsRes
    let feedbackResult = await feedback
    let responsesResult = await responses
    let reviewsResult = await reviews
    let reviewsDeltaResult = await reviewsDelta
    let appsResult = await apps
    let evS = await eventsSpark
    let usS = await usersSpark
    let seS = await sessionsSpark
    let meS = await metricsSpark
    let fuS = await funnelsSpark
    let reS = await responsesSpark

    var values: [DashboardMetric: MetricValue] = [:]
    for metric in metrics {
      switch metric {
      case .openIssues:
        if let issuesResult { values[metric] = MetricValue(value: format(issuesResult)) }
      case .events:
        if let e = eventsResult { values[metric] = MetricValue(value: format(e.count), sparkline: evS) }
      case .users:
        if let e = eventsResult { values[metric] = MetricValue(value: format(e.uniqueUsers), sparkline: usS) }
      case .sessions:
        if let e = eventsResult { values[metric] = MetricValue(value: format(e.uniqueSessions), sparkline: seS) }
      case .metrics:
        if let r = metricsResult { values[metric] = completionsValue(r, denominatorIncludesFailed: true, sparkline: meS) }
      case .funnels:
        if let r = funnelsResult { values[metric] = completionsValue(r, denominatorIncludesFailed: false, sparkline: fuS) }
      case .feedback:
        if let f = feedbackResult { values[metric] = MetricValue(value: format(f)) }
      case .responses:
        if let r = responsesResult { values[metric] = MetricValue(value: format(r), sparkline: reS) }
      case .reviews:
        if let r = reviewsResult { values[metric] = MetricValue(value: format(r), delta: reviewsDeltaResult) }
      case .avgRating:
        // Present iff the apps fetch succeeded (a successful empty result still
        // renders "—" — that's a real "no ratings", not a failure).
        if let appsResult { values[metric] = avgRatingValue(appsResult) }
      }
    }
    return DashboardSnapshot(values: values, generatedAt: Date())
  }

  /// Formats an avg-rating card from an already-loaded set of apps. Used by the
  /// dashboard, which holds apps in memory (project-scoped) and skips the fetch.
  static func avgRatingValue(_ apps: [AppModel]) -> MetricValue {
    guard let summary = ratingSummary(for: apps) else { return MetricValue(value: "—") }
    return MetricValue(
      value: String(format: "★ %.2f", summary.avg),
      secondary: StatNumberFormat.string(summary.total),
      delta: summary.delta
    )
  }

  // MARK: - Per-fetch helpers (each catches internally and returns nil)

  private static func fetchEvents(teamId: String, projectId: String?, dataMode: DataMode, since: String, want: Bool) async -> EventsCountResponse? {
    guard want else { return nil }
    return try? await EventsService.count(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
  }

  private static func fetchOpenIssues(teamId: String, projectId: String?, dataMode: DataMode, want: Bool) async -> Int? {
    guard want else { return nil }
    guard let dto = try? await IssuesService.list(teamId: teamId, projectId: projectId, dataMode: dataMode, limit: 100)
    else { return nil }
    return dto.issues.filter { IssueStatus.openStatuses.contains($0.status) }.count
  }

  private static func fetchMetrics(teamId: String, projectId: String?, dataMode: DataMode, since: String, want: Bool) async -> CompletionsCountResponse? {
    guard want else { return nil }
    return try? await MetricsService.completionsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
  }

  private static func fetchFunnels(teamId: String, projectId: String?, dataMode: DataMode, since: String, want: Bool) async -> CompletionsCountResponse? {
    guard want else { return nil }
    return try? await FunnelsService.completionsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
  }

  private static func fetchFeedback(teamId: String, projectId: String?, dataMode: DataMode, want: Bool) async -> Int? {
    guard want else { return nil }
    return try? await FeedbackService.count(teamId: teamId, projectId: projectId, status: .new, dataMode: dataMode)
  }

  private static func fetchResponses(teamId: String, projectId: String?, dataMode: DataMode, since: String, want: Bool) async -> Int? {
    guard want else { return nil }
    return try? await QuestionnairesService.count(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
  }

  private static func fetchReviews(teamId: String, projectId: String?, since: String?, want: Bool) async -> Int? {
    guard want else { return nil }
    return try? await ReviewsService.count(teamId: teamId, projectId: projectId, since: since)
  }

  private static func fetchApps(teamId: String, projectId: String?, want: Bool) async -> [AppModel]? {
    guard want else { return nil }
    return try? await AppsService.list(teamId: teamId, projectId: projectId)
  }

  private static func fetchSparkline(_ kind: StatsKind, teamId: String, projectId: String?, dataMode: DataMode, want: Bool) async -> [Double] {
    guard want else { return [] }
    guard let response = try? await StatsService.bucketed(
      kind: kind, teamId: teamId, projectId: projectId, days: 30, dataMode: dataMode
    ) else { return [] }
    return response.data.map { $0.value }
  }

  // MARK: - Formatting (mirrors DashboardView)

  private static func format(_ value: Int?) -> String {
    guard let value else { return "—" }
    return StatNumberFormat.string(value)
  }

  /// `completed/total` with a percent secondary. Metrics' total adds failures;
  /// funnels' total is the started count (mirrors `metricsValue`/`funnelsValue`).
  private static func completionsValue(
    _ response: CompletionsCountResponse,
    denominatorIncludesFailed: Bool,
    sparkline: [Double]
  ) -> MetricValue {
    let completed = response.count
    let total = denominatorIncludesFailed
      ? completed + (response.failed ?? 0)
      : (response.started ?? 0)
    let percent = total > 0
      ? "\(Int((Double(completed) / Double(total) * 100).rounded()))%"
      : nil
    // Compact from 10k so two numbers + a percent fit one narrow tile (32k/32k).
    let ratio = "\(StatNumberFormat.string(completed, compactThreshold: 10_000))/\(StatNumberFormat.string(total, compactThreshold: 10_000))"
    return MetricValue(value: ratio, secondary: percent, sparkline: sparkline)
  }
}
