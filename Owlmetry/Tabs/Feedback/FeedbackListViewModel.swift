import Combine
import Foundation
import Owlmetry

struct FeedbackFilter: Equatable {
  var appId: String? = nil
  var includeDev: Bool = true

  var hashDescription: String {
    "\(appId ?? "-")|\(includeDev)"
  }
}

@MainActor
final class FeedbackListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var items: [Feedback] = []
  @Published var filter = FeedbackFilter()

  var hasActiveFilters: Bool { filter.appId != nil || !filter.includeDev }

  func feedback(for status: FeedbackStatus) -> [Feedback] {
    items.filter { $0.status == status }
  }

  func removeLocal(id: String) {
    items.removeAll { $0.id == id }
    if items.isEmpty, case .loaded = state {
      state = .empty
    }
  }

  func replaceLocal(_ feedback: Feedback) {
    guard let index = items.firstIndex(where: { $0.id == feedback.id }) else { return }
    items[index] = feedback
  }

  func load(teamId: String, projectId: String?, dataMode: DataMode) async {
    state = .loading
    do {
      let dto = try await FeedbackService.list(
        teamId: teamId,
        projectId: projectId,
        dataMode: dataMode,
        appId: filter.appId,
        isDev: filter.includeDev ? nil : false,
        limit: 100
      )
      items = dto.feedback
      state = items.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load feedback")
      Owl.error("feedback.list.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
      Owl.error("feedback.list.failed", attributes: ["error": "\(error)"])
    }
  }
}
