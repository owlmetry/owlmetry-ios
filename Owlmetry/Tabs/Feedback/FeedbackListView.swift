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
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading where viewModel.items.isEmpty:
      LoadingState()
    case .error(let message) where viewModel.items.isEmpty:
      ErrorState(message: message) { Task { await reload() } }
    default:
      List {
        if viewModel.items.isEmpty {
          EmptyState(
            systemImage: "bubble.left",
            title: "No feedback yet",
            subtitle: "Submissions from the in-app feedback view will appear here."
          )
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        } else {
          ForEach(FeedbackStatus.allCases) { status in
            let items = viewModel.feedback(for: status)
            if !items.isEmpty {
              Section {
                ForEach(items) { feedback in
                  NavigationLink {
                    FeedbackDetailView(feedback: feedback)
                  } label: {
                    FeedbackCard(
                      feedback: feedback,
                      app: appState.apps.first(where: { $0.id == feedback.appId }),
                      project: appState.projectsById[feedback.projectId]
                    )
                  }
                  .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
                  .buttonStyle(.plain)
                }
              } header: {
                SectionHeader(title: status.displayName, count: items.count, emoji: status.emoji, tone: Theme.Status.color(for: status))
                  .textCase(nil)
              }
            }
          }
        }
      }
      .listStyle(.plain)
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
