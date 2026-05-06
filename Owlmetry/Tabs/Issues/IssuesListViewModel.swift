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
    let filtered = issues.filter { $0.status == status }
    guard status == .new else { return filtered }
    return filtered.sorted { lhs, rhs in
      if lhs.uniqueUserCount != rhs.uniqueUserCount {
        return lhs.uniqueUserCount > rhs.uniqueUserCount
      }
      return lhs.lastSeenAt > rhs.lastSeenAt
    }
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
      for failure in dto.decodeFailures {
        Owl.warn("issues.list.decode_skipped", attributes: [
          "index": "\(failure.index)",
          "reason": failure.reason
        ])
      }
      state = issues.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load issues")
      Owl.error("issues.list.failed", attributes: errorAttributes(error))
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
      Owl.error("issues.list.failed", attributes: ["error": "\(error)"])
    }
  }

  private func errorAttributes(_ error: APIError) -> [String: String] {
    var attrs = error.metricAttributes
    if case .decoding(let underlying) = error {
      attrs["detail"] = DecodingFailureSummary.string(from: underlying)
    } else {
      attrs["error"] = "\(error)"
    }
    return attrs
  }

  func applyStatusLocally(issueId: String, status: IssueStatus) {
    if let index = issues.firstIndex(where: { $0.id == issueId }) {
      var updated = issues[index]
      updated = Issue(
        id: updated.id,
        projectId: updated.projectId,
        appId: updated.appId,
        title: updated.title,
        fingerprints: updated.fingerprints,
        status: status,
        occurrenceCount: updated.occurrenceCount,
        uniqueUserCount: updated.uniqueUserCount,
        firstSeenAt: updated.firstSeenAt,
        lastSeenAt: updated.lastSeenAt,
        firstSeenAppVersion: updated.firstSeenAppVersion,
        lastSeenAppVersion: updated.lastSeenAppVersion,
        resolvedAtVersion: updated.resolvedAtVersion,
        isDev: updated.isDev,
        sourceModule: updated.sourceModule,
        createdAt: updated.createdAt,
        updatedAt: updated.updatedAt
      )
      issues[index] = updated
    }
  }
}
