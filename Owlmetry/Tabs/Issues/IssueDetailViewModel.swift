import Combine
import Foundation

@MainActor
final class IssueDetailViewModel: ObservableObject {
  @Published private(set) var issue: Issue?
  @Published private(set) var comments: [IssueComment] = []
  @Published private(set) var occurrences: [IssueOccurrence] = []
  @Published private(set) var attachments: [IssueAttachment]?
  @Published private(set) var fingerprints: [String]?
  @Published private(set) var isLoading = false
  @Published private(set) var isSubmittingComment = false
  @Published var errorMessage: String?

  func load(projectId: String, issueId: String) async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil
    do {
      let detail = try await IssuesService.detail(projectId: projectId, issueId: issueId)
      issue = detail.issue
      comments = detail.comments
      occurrences = detail.occurrences
      attachments = detail.attachments
      fingerprints = detail.fingerprints
    } catch let error as APIError {
      errorMessage = error.errorDescription
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func submitComment(projectId: String, issueId: String, body: String) async {
    let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !isSubmittingComment else { return }
    isSubmittingComment = true
    defer { isSubmittingComment = false }
    errorMessage = nil
    do {
      let created = try await IssuesService.postComment(
        projectId: projectId,
        issueId: issueId,
        body: trimmed
      )
      comments.append(created)
    } catch let error as APIError {
      errorMessage = error.errorDescription
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func updateStatus(projectId: String, issueId: String, status: IssueStatus, resolvedAtVersion: String?) async {
    do {
      let updated = try await IssuesService.updateStatus(
        projectId: projectId,
        issueId: issueId,
        status: status,
        resolvedAtVersion: resolvedAtVersion
      )
      issue = updated
    } catch let error as APIError {
      errorMessage = error.errorDescription
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
