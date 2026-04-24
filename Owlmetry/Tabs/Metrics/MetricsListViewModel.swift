import Combine
import Foundation

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
    } catch {
      state = .error(error.localizedDescription)
    }
  }
}
