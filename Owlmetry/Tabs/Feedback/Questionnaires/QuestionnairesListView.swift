import Owlmetry
import SwiftUI

struct QuestionnairesListNavRoute: Hashable {}

struct QuestionnaireDetailNavRoute: Hashable {
  let projectId: String
  let questionnaireId: String
}

struct QuestionnaireResponseDetailNavRoute: Hashable {
  let projectId: String
  let questionnaireId: String
  let responseId: String
}

struct QuestionnairesListView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = QuestionnairesListViewModel()
  @State private var showFilter = false

  var body: some View {
    content
      .navigationTitle("Questionnaires")
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
        QuestionnairesFilterSheet(
          filter: viewModel.filter,
          onApply: { new in viewModel.filter = new; Task { await reload() } },
          onClear: { viewModel.filter = QuestionnairesFilter(); Task { await reload() } }
        )
      }
      .refreshable { await reload() }
      .autoRefresh(id: refreshKey, every: 30) { await reload() }
      .toolbar(.hidden, for: .tabBar)
      .owlScreen("QuestionnairesList")
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
        if filteredItems.isEmpty {
          EmptyState(
            systemImage: "list.clipboard",
            title: "No questionnaires yet",
            subtitle: "In-app surveys you create will appear here. Define one in the web dashboard or via the CLI."
          )
        } else {
          LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {
            ForEach(grouped, id: \.projectId) { group in
              section(for: group)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
    }
  }

  private var filteredItems: [Questionnaire] {
    if let projectId = appState.selectedProjectId {
      return viewModel.items.filter { $0.projectId == projectId }
    }
    return viewModel.items
  }

  private struct ProjectGroup {
    let projectId: String
    let project: Project?
    let questionnaires: [Questionnaire]
  }

  private var grouped: [ProjectGroup] {
    let bucket = Dictionary(grouping: filteredItems, by: { $0.projectId })
    return bucket
      .map { (projectId, list) in
        ProjectGroup(
          projectId: projectId,
          project: appState.projectsById[projectId],
          questionnaires: list.sorted { ($0.lastResponseAt ?? "") > ($1.lastResponseAt ?? "") }
        )
      }
      .sorted { (a, b) in
        (a.project?.name ?? "~").localizedCaseInsensitiveCompare(b.project?.name ?? "~") == .orderedAscending
      }
  }

  @ViewBuilder
  private func section(for group: ProjectGroup) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        ProjectDot(project: group.project, size: 10)
        Text(group.project?.name ?? "Unknown project")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text("(\(group.questionnaires.count))")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      VStack(spacing: 8) {
        ForEach(group.questionnaires) { questionnaire in
          NavigationLink(value: QuestionnaireDetailNavRoute(
            projectId: questionnaire.projectId,
            questionnaireId: questionnaire.id
          )) {
            QuestionnaireCard(questionnaire: questionnaire, project: group.project)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var refreshKey: String {
    "\(appState.currentTeam?.id ?? "-")|\(appState.dataMode.rawValue)|\(viewModel.filter.hashDescription)"
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    await viewModel.load(teamId: teamId, dataMode: appState.dataMode)
  }
}

struct QuestionnairesFilterSheet: View {
  @State var filter: QuestionnairesFilter
  let onApply: (QuestionnairesFilter) -> Void
  let onClear: () -> Void

  var body: some View {
    FilterSheet(
      title: "Filter Questionnaires",
      onClear: {
        filter = QuestionnairesFilter()
        onClear()
      },
      onApply: { onApply(filter) }
    ) {
      Section("Visibility") {
        Toggle("Hide paused questionnaires", isOn: $filter.hideInactive)
      }
    }
    .owlScreen("QuestionnairesFilter")
  }
}
