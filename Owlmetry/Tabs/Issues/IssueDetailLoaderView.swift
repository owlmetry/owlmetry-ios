import Owlmetry
import SwiftUI

/// Fetches an issue by id then presents the existing IssueDetailView.
/// Used by deep-link routing — list-driven nav still pushes IssueDetailView
/// directly with a pre-loaded model.
struct IssueDetailLoaderView: View {
  let projectId: String
  let issueId: String

  @StateObject private var viewModel = IssueDetailViewModel()
  @State private var failed = false

  var body: some View {
    Group {
      if let issue = viewModel.issue {
        IssueDetailView(issue: issue)
      } else if failed {
        VStack(spacing: 8) {
          Text("Couldn't load issue")
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
    .task(id: issueId) { await load() }
    .navigationTitle("Issue")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func load() async {
    failed = false
    await viewModel.load(projectId: projectId, issueId: issueId)
    if viewModel.issue == nil { failed = true }
  }
}
