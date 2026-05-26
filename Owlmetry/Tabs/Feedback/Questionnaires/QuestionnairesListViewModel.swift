import Combine
import Foundation
import Owlmetry

struct QuestionnairesFilter: Equatable {
  var hideInactive: Bool = false

  var hashDescription: String {
    "\(hideInactive)"
  }
}

@MainActor
final class QuestionnairesListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var items: [Questionnaire] = []
  @Published var filter = QuestionnairesFilter()

  var hasActiveFilters: Bool { filter.hideInactive }

  func load(teamId: String, dataMode: DataMode) async {
    state = .loading
    do {
      let dto = try await QuestionnairesService.list(
        teamId: teamId,
        dataMode: dataMode,
        isActive: filter.hideInactive ? true : nil
      )
      items = dto.questionnaires
      state = items.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load questionnaires")
      Owl.error("questionnaires.list.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
      Owl.error("questionnaires.list.failed", attributes: ["error": "\(error)"])
    }
  }
}
