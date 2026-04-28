import Combine
import Foundation
import Owlmetry

@MainActor
final class MetricsListViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var metrics: [MetricDefinition] = []
  @Published private(set) var statsBySlug: [String: MetricStatsEntry] = [:]

  func load(projectId: String?, dataMode: DataMode = .production) async {
    guard let projectId else {
      state = .idle
      metrics = []
      statsBySlug = [:]
      return
    }
    state = .loading
    do {
      async let definitions = MetricsService.list(projectId: projectId)
      async let stats = MetricsService.stats(projectId: projectId, dataMode: dataMode)
      let (defs, statsList) = try await (definitions, stats)
      metrics = defs
      statsBySlug = Dictionary(uniqueKeysWithValues: statsList.map { ($0.slug, $0) })
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
