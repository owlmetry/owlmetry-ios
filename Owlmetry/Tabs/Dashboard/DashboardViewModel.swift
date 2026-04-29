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
  @Published var reviewsCount: Int?
  @Published var reviewsDelta: Int?
  @Published var lastUpdatedAt: Date?

  @Published var errorMessage: String?

  func load(teamId: String, projectId: String?, dataMode: DataMode) async {
    let since = ISODate.isoString(since: 86_400)

    async let openIssues = fetchOpenIssuesCount(teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let events = fetchEventsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let metrics = fetchMetricsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let funnels = fetchFunnelsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let reviews = fetchReviewsCount(teamId: teamId, projectId: projectId)
    async let reviewsRecent = fetchReviewsCount(teamId: teamId, projectId: projectId, since: since)

    let openIssuesResult = await openIssues
    let eventsResult = await events
    let metricsResult = await metrics
    let funnelsResult = await funnels
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
    if let v = reviewsResult { reviewsCount = v }
    if let v = reviewsDeltaResult { reviewsDelta = v }

    if Task.isCancelled { return }

    let allFailed = openIssuesResult == nil
      && eventsResult == nil
      && metricsResult == nil
      && funnelsResult == nil
      && reviewsResult == nil
    let anyCachedData = openIssuesCount != nil
      || eventsCount != nil
      || metricsCompletedCount != nil
      || funnelsCompletedCount != nil
      || reviewsCount != nil
    if allFailed && !anyCachedData {
      errorMessage = "Couldn't load dashboard. Pull to retry."
    } else {
      errorMessage = nil
      lastUpdatedAt = Date()
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
}
