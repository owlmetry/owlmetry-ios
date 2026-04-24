import Owlmetry
import SwiftUI

struct FeedbackListView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = FeedbackListViewModel()
  @State private var showFilter = false

  var body: some View {
    content
      .navigationTitle("Feedback")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button { showFilter = true } label: {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
          }
        }
        ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
      }
      .sheet(isPresented: $showFilter) {
        FeedbackFilterSheet(
          filter: viewModel.filter,
          apps: appState.apps.filter { appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId },
          onApply: { new in viewModel.filter = new; Task { await reload() } },
          onClear: { viewModel.filter = FeedbackFilter(); Task { await reload() } }
        )
      }
      .refreshable { await reload() }
      .autoRefresh(id: refreshKey, every: 30) { await reload() }
      .owlScreen("FeedbackList")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading where viewModel.items.isEmpty:
      LoadingState()
    case .error(let message) where viewModel.items.isEmpty:
      ErrorState(message: message) { Task { await reload() } }
    default:
      ScrollView {
        if viewModel.items.isEmpty {
          EmptyState(
            systemImage: "bubble.left",
            title: "No feedback yet",
            subtitle: "Submissions from the in-app feedback view will appear here."
          )
        } else {
          LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
            ForEach(FeedbackStatus.allCases) { status in
              let items = viewModel.feedback(for: status)
              if !items.isEmpty {
                SectionHeader(title: status.displayName, count: items.count, emoji: status.emoji, tone: Theme.Status.color(for: status))
                  .textCase(nil)
                  .padding(.top, 4)
                VStack(spacing: 8) {
                  ForEach(items) { feedback in
                    NavigationLink {
                      FeedbackDetailView(
                        feedback: feedback,
                        onDeleted: { deletedId in
                          viewModel.removeLocal(id: deletedId)
                        },
                        onUpdated: { updated in
                          viewModel.replaceLocal(updated)
                        }
                      )
                    } label: {
                      FeedbackCard(
                        feedback: feedback,
                        app: appState.apps.first(where: { $0.id == feedback.appId }),
                        project: appState.projectsById[feedback.projectId]
                      )
                    }
                    .buttonStyle(.plain)
                  }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
              }
            }
          }
        }
      }
    }
  }

  private var refreshKey: String {
    "\(appState.currentTeam?.id ?? "-")|\(appState.selectedProjectId ?? "all")|\(appState.dataMode.rawValue)|\(viewModel.filter.hashDescription)"
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    await viewModel.load(teamId: teamId, projectId: appState.selectedProjectId, dataMode: appState.dataMode)
  }
}
