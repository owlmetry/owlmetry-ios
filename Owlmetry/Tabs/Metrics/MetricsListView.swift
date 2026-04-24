import SwiftUI

struct MetricsListView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = MetricsListViewModel()

  private let columns: [GridItem] = [
    GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 12)
  ]

  var body: some View {
    content
      .navigationTitle("Metrics")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
      }
      .refreshable { await viewModel.load(projectId: appState.selectedProjectId) }
      .task(id: appState.selectedProjectId) {
        await viewModel.load(projectId: appState.selectedProjectId)
      }
  }

  @ViewBuilder
  private var content: some View {
    if appState.selectedProjectId == nil {
      EmptyState(
        systemImage: "square.grid.2x2",
        title: "Pick a project",
        subtitle: "Metrics are scoped to one project at a time. Select one from the top right menu."
      )
    } else {
      switch viewModel.state {
      case .idle, .loading:
        LoadingState()
      case .empty:
        EmptyState(systemImage: "chart.bar", title: "No metrics yet", subtitle: "Metrics defined in this project will appear here.")
      case .error(let message):
        ErrorState(message: message) {
          Task { await viewModel.load(projectId: appState.selectedProjectId) }
        }
      case .loaded:
        ScrollView {
          LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.metrics) { metric in
              NavigationLink {
                MetricDetailView(metric: metric)
              } label: {
                MetricCard(metric: metric, project: appState.projectsById[metric.projectId])
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
    }
  }
}
