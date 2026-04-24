import Combine
import Foundation

@MainActor
final class FeedbackDetailViewModel: ObservableObject {
  @Published private(set) var feedback: Feedback?
  @Published private(set) var comments: [FeedbackComment] = []
  @Published var errorMessage: String?

  func load(projectId: String, feedbackId: String) async {
    do {
      let detail = try await FeedbackService.detail(projectId: projectId, feedbackId: feedbackId)
      feedback = detail.feedback
      comments = detail.comments
    } catch let error as APIError {
      errorMessage = error.errorDescription
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func updateStatus(projectId: String, feedbackId: String, status: FeedbackStatus) async {
    do {
      feedback = try await FeedbackService.updateStatus(projectId: projectId, feedbackId: feedbackId, status: status)
    } catch let error as APIError {
      errorMessage = error.errorDescription
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
