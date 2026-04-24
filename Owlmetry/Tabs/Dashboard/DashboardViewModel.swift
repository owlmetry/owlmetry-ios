import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
  @Published var openIssuesCount: Int?
  @Published var eventsCount: Int?
  @Published var uniqueUsers: Int?
  @Published var uniqueSessions: Int?
  @Published var metricsCount: Int?
  @Published var funnelsCompletedCount: Int?
  @Published var funnelsStartedCount: Int?
  @Published var projectCount: Int?
  @Published var appCount: Int?

  @Published var errorMessage: String?

  func load(teamId: String, projectId: String?, dataMode: DataMode, knownProjectCount: Int, knownAppCount: Int) async {
    errorMessage = nil
    projectCount = knownProjectCount
    appCount = knownAppCount

    let since = ISODate.isoString(since: 86_400)

    async let openIssues = fetchOpenIssuesCount(teamId: teamId, projectId: projectId, dataMode: dataMode)
    async let events = fetchEventsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let metrics = fetchMetricsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    async let funnels = fetchFunnelsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)

    openIssuesCount = await openIssues
    let eventsResponse = await events
    eventsCount = eventsResponse?.count
    uniqueUsers = eventsResponse?.uniqueUsers
    uniqueSessions = eventsResponse?.uniqueSessions
    metricsCount = await metrics
    let funnelsResponse = await funnels
    funnelsCompletedCount = funnelsResponse?.count
    funnelsStartedCount = funnelsResponse?.started
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
      errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
      return nil
    }
  }

  private func fetchEventsCount(teamId: String, projectId: String?, since: String, dataMode: DataMode) async -> EventsCountResponse? {
    do {
      return try await EventsService.count(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    } catch {
      errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
      return nil
    }
  }

  private func fetchMetricsCount(teamId: String, projectId: String?, since: String, dataMode: DataMode) async -> Int? {
    do {
      let r = try await MetricsService.completionsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
      return r.count
    } catch {
      errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
      return nil
    }
  }

  private func fetchFunnelsCount(teamId: String, projectId: String?, since: String, dataMode: DataMode) async -> CompletionsCountResponse? {
    do {
      return try await FunnelsService.completionsCount(teamId: teamId, projectId: projectId, since: since, dataMode: dataMode)
    } catch {
      errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
      return nil
    }
  }
}
