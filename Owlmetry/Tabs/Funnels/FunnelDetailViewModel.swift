import Combine
import Foundation
import Owlmetry

@MainActor
final class FunnelDetailViewModel: ObservableObject {
  @Published var range: MetricTimeRange = .last24h
  @Published private(set) var analytics: FunnelAnalytics?
  @Published var isLoading = false
  @Published var errorMessage: String?

  func load(slug: String, teamId: String, projectId: String, dataMode: DataMode) async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil
    let since = ISODate.isoString(since: range.seconds)
    do {
      analytics = try await FunnelsService.analytics(
        slug: slug,
        projectId: projectId,
        since: since,
        dataMode: dataMode
      )
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Owl.error("funnel.detail.load.failed", attributes: ["error": "\(error)", "slug": slug])
    } catch {
      if error.isCancellation { return }
      errorMessage = error.localizedDescription
      Owl.error("funnel.detail.load.failed", attributes: ["error": "\(error)", "slug": slug])
    }
  }
}
