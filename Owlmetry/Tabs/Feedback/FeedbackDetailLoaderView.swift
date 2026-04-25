import Owlmetry
import SwiftUI

/// Fetches feedback by id then presents the existing FeedbackDetailView.
/// Used by deep-link routing.
struct FeedbackDetailLoaderView: View {
  let projectId: String
  let feedbackId: String

  @StateObject private var viewModel = FeedbackDetailViewModel()
  @State private var failed = false

  var body: some View {
    Group {
      if let feedback = viewModel.feedback {
        FeedbackDetailView(feedback: feedback)
      } else if failed {
        VStack(spacing: 8) {
          Text("Couldn't load feedback")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          if let msg = viewModel.errorMessage {
            Text(msg).font(.caption).foregroundStyle(.tertiary)
          }
          Button("Retry") { Task { await load() } }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .task(id: feedbackId) { await load() }
    .navigationTitle("Feedback")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func load() async {
    failed = false
    await viewModel.load(projectId: projectId, feedbackId: feedbackId)
    if viewModel.feedback == nil { failed = true }
  }
}
