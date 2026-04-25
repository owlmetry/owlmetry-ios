import Combine
import Foundation
import Owlmetry

@MainActor
final class MetricsListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var metrics: [MetricDefinition] = []

  func load(projectId: String?) async {
    guard let projectId else {
      state = .idle
      metrics = []
      return
    }
    state = .loading
    do {
      metrics = try await MetricsService.list(projectId: projectId)
      state = metrics.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load metrics")
      Owl.error("metrics.list.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
      Owl.error("metrics.list.failed", attributes: ["error": "\(error)"])
    }
  }
}
