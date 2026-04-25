import Owlmetry
import SwiftUI

struct UsersListView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = UsersListViewModel()
  @StateObject private var debounced = DebouncedText()
  @State private var showFilter = false

  var body: some View {
    content
      .navigationTitle("Users")
      .navigationBarTitleDisplayMode(.large)
      .searchable(text: $debounced.text, prompt: "Search by user ID")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          HStack(spacing: 8) {
            Button { showFilter = true } label: {
              Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            sortMenu
          }
        }
        ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
      }
      .sheet(isPresented: $showFilter) {
        UsersFilterSheet(
          filter: viewModel.filter,
          apps: appState.apps.filter { appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId },
          onApply: { new in
            viewModel.filter = new
            Task { await reload() }
          },
          onClear: {
            viewModel.filter = UsersFilter()
            Task { await reload() }
          }
        )
      }
      .onChange(of: debounced.debounced) { _, value in
        viewModel.filter.search = value
        Task { await reload() }
      }
      .refreshable { await reload() }
      .task(id: refreshKey) { await reload() }
      .owlScreen("UsersList")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading where viewModel.users.isEmpty:
      LoadingState()
    case .error(let message) where viewModel.users.isEmpty:
      ErrorState(message: message) { Task { await reload() } }
    default:
      ScrollView {
        if viewModel.users.isEmpty {
          EmptyState(systemImage: "person.2", title: "No users yet", subtitle: "Users from recent sessions will appear here.")
        } else {
          LazyVStack(spacing: 8) {
            ForEach(viewModel.users) { user in
              NavigationLink {
                UserDetailView(user: user)
              } label: {
                UserCard(
                  user: user,
                  apps: (user.apps ?? []).compactMap { info in appState.apps.first(where: { $0.id == info.appId }) },
                  projectsById: appState.projectsById
                )
              }
              .buttonStyle(.plain)
              .task {
                guard let teamId = appState.currentTeam?.id else { return }
                await viewModel.loadMoreIfNeeded(
                  teamId: teamId,
                  projectId: appState.selectedProjectId,
                  dataMode: appState.dataMode,
                  currentUser: user
                )
              }
            }
            if viewModel.isLoadingMore {
              ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 4)
          .padding(.bottom, 8)
        }
      }
    }
  }

  private var sortMenu: some View {
    Menu {
      Button {
        viewModel.filter.sort = .lastSeen
        Task { await reload() }
      } label: {
        Label("Most recently seen", systemImage: viewModel.filter.sort == .lastSeen ? "checkmark" : "clock")
      }
      Button {
        viewModel.filter.sort = .firstSeen
        Task { await reload() }
      } label: {
        Label("Newest first seen", systemImage: viewModel.filter.sort == .firstSeen ? "checkmark" : "sparkles")
      }
    } label: {
      Image(systemName: "arrow.up.arrow.down")
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
