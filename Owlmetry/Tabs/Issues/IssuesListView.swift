import Owlmetry
import SwiftUI

struct IssuesListView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = IssuesListViewModel()
  @State private var showFilter = false

  var body: some View {
    content
      .navigationTitle("Issues")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button { showFilter = true } label: {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          ProjectSelectorMenu()
        }
      }
      .sheet(isPresented: $showFilter) {
        IssueFilterSheet(
          filter: viewModel.filter,
          apps: appState.apps.filter { appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId },
          onApply: { new in
            viewModel.filter = new
            Task { await reload() }
          },
          onClear: {
            viewModel.filter = IssueFilter()
            Task { await reload() }
          }
        )
      }
      .refreshable { await reload() }
      .autoRefresh(id: refreshKey, every: 30) { await reload() }
      .owlScreen("IssuesList")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading where viewModel.issues.isEmpty:
      LoadingState()
    case .error(let message) where viewModel.issues.isEmpty:
      ErrorState(message: message) {
        Task { await reload() }
      }
    default:
      ScrollView {
        if viewModel.issues.isEmpty {
          EmptyState(
            systemImage: "ladybug",
            title: "No issues yet",
            subtitle: "Issues from recent sessions will appear here when the SDK reports errors."
          )
        } else {
          LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
            ForEach(IssueStatus.allCases) { status in
              let issues = viewModel.issues(for: status)
              if !issues.isEmpty {
                SectionHeader(title: status.displayName, count: issues.count, emoji: status.emoji, tone: Theme.Status.color(for: status))
                  .textCase(nil)
                  .padding(.top, 4)
                VStack(spacing: 8) {
                  ForEach(issues) { issue in
                    NavigationLink {
                      IssueDetailView(issue: issue)
                    } label: {
                      IssueCard(
                        issue: issue,
                        app: appState.apps.first(where: { $0.id == issue.appId }),
                        project: appState.projectsById[issue.projectId]
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
