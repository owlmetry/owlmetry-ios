import Owlmetry
import SwiftUI

struct FunnelsListView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = FunnelsListViewModel()

  var projectIdOverride: String? = nil

  private let columns: [GridItem] = [
    GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 12)
  ]

  private var effectiveProjectId: String? {
    projectIdOverride ?? appState.selectedProjectId
  }

  var body: some View {
    content
      .navigationTitle("Funnels")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        if projectIdOverride == nil {
          ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
        }
      }
      .refreshable { await viewModel.load(projectId: effectiveProjectId) }
      .task(id: effectiveProjectId) {
        await viewModel.load(projectId: effectiveProjectId)
      }
      .toolbar(.hidden, for: .tabBar)
      .owlScreen("FunnelsList")
  }

  @ViewBuilder
  private var content: some View {
    if effectiveProjectId == nil {
      EmptyState(
        systemImage: "square.grid.2x2",
        title: "Pick a project",
        subtitle: "Funnels are scoped to one project at a time. Select one from the top right menu."
      )
    } else {
      switch viewModel.state {
      case .idle, .loading:
        LoadingState()
      case .empty:
        EmptyState(systemImage: "line.3.horizontal.decrease.circle", title: "No funnels yet", subtitle: "Funnels defined in this project will appear here.")
      case .error(let message):
        ErrorState(message: message) {
          Task { await viewModel.load(projectId: effectiveProjectId) }
        }
      case .loaded:
        ScrollView {
          LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.funnels) { funnel in
              NavigationLink {
                FunnelDetailView(funnel: funnel)
              } label: {
                FunnelCard(funnel: funnel, project: appState.projectsById[funnel.projectId])
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
