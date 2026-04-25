import Combine
import Foundation
import Owlmetry

enum MetricTimeRange: String, CaseIterable, Identifiable {
  case last24h = "24h"
  case last7d = "7d"
  case last30d = "30d"

  var id: String { rawValue }

  var seconds: TimeInterval {
    switch self {
    case .last24h: return 86_400
    case .last7d: return 86_400 * 7
    case .last30d: return 86_400 * 30
    }
  }

  var displayName: String {
    switch self {
    case .last24h: return "24h"
    case .last7d: return "7d"
    case .last30d: return "30d"
    }
  }
}

@MainActor
final class MetricDetailViewModel: ObservableObject {
  @Published var range: MetricTimeRange = .last24h
  @Published private(set) var aggregation: MetricAggregation?
  @Published private(set) var events: [StoredMetricEvent] = []
  @Published var errorMessage: String?
  @Published var isLoading = false

  func load(slug: String, teamId: String, projectId: String, dataMode: DataMode) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }
    let since = ISODate.isoString(since: range.seconds)
    do {
      async let aggregation = MetricsService.aggregation(
        slug: slug,
        projectId: projectId,
        since: since,
        dataMode: dataMode
      )
      async let events = MetricsService.events(
        slug: slug,
        projectId: projectId,
        dataMode: dataMode,
        limit: 20
      )
      self.aggregation = try await aggregation
      self.events = try await events.events
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Owl.error("metric.detail.load.failed", attributes: ["error": "\(error)", "slug": slug])
    } catch {
      if error.isCancellation { return }
      errorMessage = error.localizedDescription
      Owl.error("metric.detail.load.failed", attributes: ["error": "\(error)", "slug": slug])
    }
  }
}
