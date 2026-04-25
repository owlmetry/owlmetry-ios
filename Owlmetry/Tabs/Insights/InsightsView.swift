import Owlmetry
import SwiftUI

struct InsightsView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        if displayProjects.isEmpty {
          EmptyState(
            systemImage: "square.grid.2x2",
            title: "No projects yet",
            subtitle: "Create a project to start tracking metrics and funnels."
          )
          .padding(.top, 40)
        } else {
          ForEach(displayProjects) { project in
            ProjectInsightsSection(project: project)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .navigationTitle("Insights")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
    }
    .owlScreen("Insights")
  }

  private var displayProjects: [Project] {
    if let selected = appState.selectedProject {
      return [selected]
    }
    return appState.projectsForCurrentTeam
  }
}

private struct ProjectInsightsSection: View {
  let project: Project

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Circle()
          .fill(ProjectColor(project: project).base)
          .frame(width: 8, height: 8)
        Text(project.name)
          .font(.headline)
          .foregroundStyle(.primary)
      }
      .padding(.horizontal, 4)

      VStack(spacing: 12) {
        NavigationLink {
          MetricsListView(projectIdOverride: project.id)
        } label: {
          NavigableCard(accent: ProjectColor(project: project).base) {
            Label("Metrics", systemImage: "chart.bar")
              .font(.headline)
              .foregroundStyle(.primary)
            Text("Track start / complete / fail / cancel / record events with durations and success rates.")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .buttonStyle(.plain)

        NavigationLink {
          FunnelsListView(projectIdOverride: project.id)
        } label: {
          NavigableCard(accent: ProjectColor(project: project).base) {
            Label("Funnels", systemImage: "line.3.horizontal.decrease.circle")
              .font(.headline)
              .foregroundStyle(.primary)
            Text("See where users drop off across a sequence of steps.")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
}
