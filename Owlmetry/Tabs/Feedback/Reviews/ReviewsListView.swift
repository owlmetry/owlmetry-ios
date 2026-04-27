import Owlmetry
import SwiftUI

struct ReviewsListView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = ReviewsListViewModel()
  @State private var showFilter = false

  var body: some View {
    content
      .navigationTitle("App Store Reviews")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button { showFilter = true } label: {
            Image(systemName: viewModel.hasActiveFilters
              ? "line.3.horizontal.decrease.circle.fill"
              : "line.3.horizontal.decrease.circle")
          }
        }
        ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
      }
      .sheet(isPresented: $showFilter) {
        ReviewFilterSheet(
          filter: viewModel.filter,
          apps: appState.apps.filter {
            appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId
          },
          onApply: { new in viewModel.filter = new; Task { await reload() } },
          onClear: { viewModel.filter = ReviewFilter(); Task { await reload() } }
        )
      }
      .refreshable { await reload() }
      .autoRefresh(id: refreshKey, every: 60) { await reload() }
      .toolbar(.hidden, for: .tabBar)
      .owlScreen("ReviewsList")
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
            systemImage: "star.bubble",
            title: "No reviews yet",
            subtitle: "App Store reviews appear here once your apps have ratings."
          )
        } else {
          LazyVStack(spacing: 8) {
            ForEach(viewModel.items) { review in
              NavigationLink {
                ReviewDetailView(review: review)
              } label: {
                ReviewCard(
                  review: review,
                  app: appState.apps.first(where: { $0.id == review.appId }),
                  project: appState.projectsById[review.projectId]
                )
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 8)
          .padding(.bottom, 12)
        }
      }
    }
  }

  private var refreshKey: String {
    "\(appState.currentTeam?.id ?? "-")|\(appState.selectedProjectId ?? "all")|\(viewModel.filter.hashDescription)"
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    await viewModel.load(teamId: teamId, projectId: appState.selectedProjectId)
  }
}
