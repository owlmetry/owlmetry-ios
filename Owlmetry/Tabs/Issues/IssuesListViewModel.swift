import Combine
import Foundation
import Owlmetry

struct IssueFilter: Equatable {
  var appId: String? = nil
  var includeDev: Bool = true

  var hashDescription: String {
    "\(appId ?? "-")|\(includeDev)"
  }
}

@MainActor
final class IssuesListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var issues: [Issue] = []
  @Published var filter = IssueFilter()

  var hasActiveFilters: Bool {
    filter.appId != nil || !filter.includeDev
  }

  func issues(for status: IssueStatus) -> [Issue] {
    issues.filter { $0.status == status }
  }

  func load(teamId: String, projectId: String?, dataMode: DataMode) async {
    state = .loading
    do {
      let dto = try await IssuesService.list(
        teamId: teamId,
        projectId: projectId,
        dataMode: dataMode,
        appId: filter.appId,
        isDev: filter.includeDev ? nil : false,
        limit: 100
      )
      issues = dto.issues
      state = issues.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load issues")
      Owl.error("issues.list.failed", attributes: ["error": "\(error)"])
    } catch {
      state = .error(error.localizedDescription)
      Owl.error("issues.list.failed", attributes: ["error": "\(error)"])
    }
  }

  func applyStatusLocally(issueId: String, status: IssueStatus) {
    if let index = issues.firstIndex(where: { $0.id == issueId }) {
      var updated = issues[index]
      updated = Issue(
        id: updated.id,
        projectId: updated.projectId,
        appId: updated.appId,
        title: updated.title,
        fingerprint: updated.fingerprint,
        status: status,
        occurrenceCount: updated.occurrenceCount,
        uniqueUserCount: updated.uniqueUserCount,
        firstSeenAt: updated.firstSeenAt,
        lastSeenAt: updated.lastSeenAt,
        firstSeenAppVersion: updated.firstSeenAppVersion,
        lastSeenAppVersion: updated.lastSeenAppVersion,
        resolvedAtVersion: updated.resolvedAtVersion,
        isDev: updated.isDev,
        source: updated.source,
        environment: updated.environment,
        createdAt: updated.createdAt,
        updatedAt: updated.updatedAt
      )
      issues[index] = updated
    }
  }
}
