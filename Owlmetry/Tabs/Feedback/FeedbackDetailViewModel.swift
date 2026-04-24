import Combine
import Foundation
import Owlmetry

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
      Owl.error("feedback.detail.load.failed", attributes: ["error": "\(error)", "feedback_id": feedbackId])
    } catch {
      errorMessage = error.localizedDescription
      Owl.error("feedback.detail.load.failed", attributes: ["error": "\(error)", "feedback_id": feedbackId])
    }
  }

  func updateStatus(projectId: String, feedbackId: String, status: FeedbackStatus) async {
    do {
      feedback = try await FeedbackService.updateStatus(projectId: projectId, feedbackId: feedbackId, status: status)
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Owl.error("feedback.status.update.failed", attributes: ["error": "\(error)", "feedback_id": feedbackId, "status": status.rawValue])
    } catch {
      errorMessage = error.localizedDescription
      Owl.error("feedback.status.update.failed", attributes: ["error": "\(error)", "feedback_id": feedbackId, "status": status.rawValue])
    }
  }

  func deleteFeedback(projectId: String, feedbackId: String) async -> Bool {
    do {
      try await FeedbackService.remove(projectId: projectId, feedbackId: feedbackId)
      return true
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Owl.error("feedback.delete.failed", attributes: ["error": "\(error)", "feedback_id": feedbackId])
      return false
    } catch {
      errorMessage = error.localizedDescription
      Owl.error("feedback.delete.failed", attributes: ["error": "\(error)", "feedback_id": feedbackId])
      return false
    }
  }
}
