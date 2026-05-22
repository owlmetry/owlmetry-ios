import Combine
import Foundation
import Owlmetry

@MainActor
final class DashboardViewModel: ObservableObject {
  @Published var openIssuesCount: Int?
  @Published var eventsCount: Int?
  @Published var uniqueUsers: Int?
  @Published var uniqueSessions: Int?
  @Published var metricsCompletedCount: Int?
  @Published var metricsFailedCount: Int?
  @Published var funnelsCompletedCount: Int?
  @Published var funnelsStartedCount: Int?
  @Published var newFeedbackCount: Int?
  @Published var questionnaireResponsesCount: Int?
  @Published var reviewsCount: Int?
  @Published var reviewsDelta: Int?
  @Published var lastUpdatedAt: Date?

  // Sparkline series. Default to `[]` (not `nil`) so the sparkline slot stays
  // reserved on first load and the card doesn't pop in height when data
  // arrives. Web's `useDailyStats` has the same semantics.
  @Published var eventsSpark: [Double] = []
  @Published var usersSpark: [Double] = []
  @Published var sessionsSpark: [Double] = []
  @Published var metricsSpark: [Double] = []
  @Published var funnelsSpark: [Double] = []
  @Published var responsesSpark: [Double] = []

  @Published var errorMessage: String?

  // Sparklines describe a multi-day trend, so re-fetching at the 30s
  // count-card cadence is overkill. Match the web hook's `5 * 60_000`
  // SWR refreshInterval. Scope change (team / project / data mode)
  // forces a refresh regardless.
  private static let sparklineMaxAgeSeconds: TimeInterval = 5 * 60
  private static let sparklineWindowDays: Int = 30
  private var lastSparklineLoadAt: Date?
  private var lastSparklineScope: String?

  func load(teamId: String, projectId: String?, dataMode: DataMode) async {
    let since = ISODate.isoString(since: 86_400)

    async let openIssues = fetchOpenIssuesCount(teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let events = fetchEventsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let metrics = fetchMetricsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let funnels = fetchFunnelsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let feedback = fetchFeedbackCount(teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let questionnaires = fetchQuestionnairesCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let reviews = fetchReviewsCount(teamId: teamId, projectId: projectId)
    async let reviewsRecent = fetchReviewsCount(teamId: teamId, projectId: projectId, since: since)

    let openIssuesResult = await openIssues
    let eventsResult = await events
    let metricsResult = await metrics
    let funnelsResult = await funnels
    let feedbackResult = await feedback
    let questionnairesResult = await questionnaires
    let reviewsResult = await reviews
    let reviewsDeltaResult = await reviewsRecent

    if let v = openIssuesResult { openIssuesCount = v }
    if let r = eventsResult {
      eventsCount = r.count
      uniqueUsers = r.uniqueUsers
      uniqueSessions = r.uniqueSessions
    }
    if let r = metricsResult {
      metricsCompletedCount = r.count
      metricsFailedCount = r.failed ?? 0
    }
    if let r = funnelsResult {
      funnelsCompletedCount = r.count
      funnelsStartedCount = r.started
    }
    if let v = feedbackResult { newFeedbackCount = v }
    if let v = questionnairesResult { questionnaireResponsesCount = v }
    if let v = reviewsResult { reviewsCount = v }
    if let v = reviewsDeltaResult { reviewsDelta = v }

    if Task.isCancelled { return }

    await refreshSparklinesIfNeeded(teamId: teamId, projectId: projectId, dataMode: dataMode)

    if Task.isCancelled { return }

    let allFailed = openIssuesResult == nil
      && eventsResult == nil
      && metricsResult == nil
      && funnelsResult == nil
      && feedbackResult == nil
      && questionnairesResult == nil
      && reviewsResult == nil
    let anyCachedData = openIssuesCount != nil
      || eventsCount != nil
      || metricsCompletedCount != nil
      || funnelsCompletedCount != nil
      || newFeedbackCount != nil
      || questionnaireResponsesCount != nil
      || reviewsCount != nil
    if allFailed && !anyCachedData {
      errorMessage = "Couldn't load dashboard. Pull to retry."
    } else {
      errorMessage = nil
      lastUpdatedAt = Date()
    }
  }

  private func refreshSparklinesIfNeeded(teamId: String, projectId: String?, dataMode: DataMode) async {
    let scope = "\(teamId)|\(projectId ?? "-")|\(dataMode.rawValue)"
    let scopeChanged = scope != lastSparklineScope
    let isStale = lastSparklineLoadAt.map {
      Date().timeIntervalSince($0) > Self.sparklineMaxAgeSeconds
    } ?? true
    guard scopeChanged || isStale else { return }

    async let events = fetchSparkline(.events, teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let users = fetchSparkline(.users, teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let sessions = fetchSparkline(.sessions, teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let metrics = fetchSparkline(.metricCompletions, teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let funnels = fetchSparkline(.funnelCompletions, teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let responses = fetchSparkline(.questionnaireResponses, teamId: teamId, projectId: projectId, dataMode: dataMode)

    let eventsRes = await events
    let usersRes = await users
    let sessionsRes = await sessions
    let metricsRes = await metrics
    let funnelsRes = await funnels
    let responsesRes = await responses

    if let r = eventsRes { eventsSpark = r }
    if let r = usersRes { usersSpark = r }
    if let r = sessionsRes { sessionsSpark = r }
    if let r = metricsRes { metricsSpark = r }
    if let r = funnelsRes { funnelsSpark = r }
    if let r = responsesRes { responsesSpark = r }

    lastSparklineLoadAt = Date()
    lastSparklineScope = scope
  }

  private func fetchSparkline(
    _ kind: StatsKind,
    teamId: String,
    projectId: String?,
    dataMode: DataMode
  ) async -> [Double]? {
    do {
      let response = try await StatsService.bucketed(
        kind: kind,
        teamId: teamId,
        projectId: projectId,
        days: Self.sparklineWindowDays,
        dataMode: dataMode
      )
      return response.data.map { $0.value }
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "spark_\(kind.rawValue)", "error": "\(error)"])
      }
      return nil
    }
  }

  private func fetchReviewsCount(teamId: String, projectId: String?, since: String? = nil) async -> Int? {
    do {
      return try await ReviewsService.count(teamId: teamId, projectId: projectId, since: since)
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "reviews", "error": "\(error)"])
      }
      return nil
    }
  }

  private func fetchOpenIssuesCount(teamId: String, projectId: String?, dataMode: DataMode) async -> Int? {
    do {
      let dto = try await IssuesService.list(
        teamId: teamId,
        projectId: projectId,
        dataMode: dataMode,
        limit: 100
      )
      return dto.issues.filter { IssueStatus.openStatuses.contains($0.status) }.count
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "issues", "error": "\(error)"])
      }
      return nil
    }
  }

  private func fetchEventsCount(teamId: String, projectId: String?, since: String, dataMode: DataMode) async -> EventsCountResponse? {
    do {
      return try await EventsService.count(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "events", "error": "\(error)"])
      }
      return nil
    }
  }

  private func fetchMetricsCount(teamId: String, projectId: String?, since: String, dataMode: DataMode) async -> CompletionsCountResponse? {
    do {
      return try await MetricsService.completionsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "metrics", "error": "\(error)"])
      }
      return nil
    }
  }

  private func fetchFunnelsCount(teamId: String, projectId: String?, since: String, dataMode: DataMode) async -> CompletionsCountResponse? {
    do {
      return try await FunnelsService.completionsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "funnels", "error": "\(error)"])
      }
      return nil
    }
  }

  private func fetchFeedbackCount(teamId: String, projectId: String?, dataMode: DataMode) async -> Int? {
    do {
      return try await FeedbackService.count(
        teamId: teamId,
        projectId: projectId,
        status: .new,
        dataMode: dataMode
      )
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "feedback", "error": "\(error)"])
      }
      return nil
    }
  }

  private func fetchQuestionnairesCount(teamId: String, projectId: String?, since: String, dataMode: DataMode) async -> Int? {
    do {
      return try await QuestionnairesService.count(
        teamId: teamId,
        projectId: projectId,
        since: since,
        dataMode: dataMode
      )
    } catch {
      if !error.isCancellation {
        Owl.error("dashboard.load.failed", attributes: ["kind": "questionnaires", "error": "\(error)"])
      }
      return nil
    }
  }
}
