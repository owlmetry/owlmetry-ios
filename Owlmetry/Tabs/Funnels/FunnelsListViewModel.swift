import Combine
import Foundation

@MainActor
final class FunnelsListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var funnels: [FunnelDefinition] = []

  func load(projectId: String?) async {
    guard let projectId else {
      state = .idle
      funnels = []
      return
    }
    state = .loading
    do {
      funnels = try await FunnelsService.list(projectId: projectId)
      state = funnels.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load funnels")
    } catch {
      state = .error(error.localizedDescription)
    }
  }
}
