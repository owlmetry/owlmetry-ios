import Combine
import Foundation
import Owlmetry

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
      Owl.error("funnels.list.failed", attributes: ["error": "\(error)"])
    } catch {
      state = .error(error.localizedDescription)
      Owl.error("funnels.list.failed", attributes: ["error": "\(error)"])
    }
  }
}
