import Combine
import Foundation
import Owlmetry

@MainActor
final class ReviewsListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var items: [Review] = []
  @Published var filter = ReviewFilter()

  var hasActiveFilters: Bool {
    filter.appId != nil
      || filter.store != nil
      || filter.rating != nil
      || !filter.search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func load(teamId: String, projectId: String?) async {
    state = .loading
    do {
      let dto = try await ReviewsService.list(
        teamId: teamId,
        projectId: projectId,
        appId: filter.appId,
        store: filter.store,
        rating: filter.rating,
        search: filter.search,
        limit: 100
      )
      items = dto.reviews
      state = items.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load reviews")
      Owl.error("reviews.list.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
      Owl.error("reviews.list.failed", attributes: ["error": "\(error)"])
    }
  }
}
