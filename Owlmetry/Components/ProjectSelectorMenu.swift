import SwiftUI

struct ProjectSelectorMenu: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    Menu {
      Button {
        appState.setSelectedProject(nil)
      } label: {
        Label("All projects", systemImage: appState.selectedProjectId == nil ? "checkmark" : "")
      }
      if !appState.projectsForCurrentTeam.isEmpty {
        Divider()
      }
      ForEach(appState.projectsForCurrentTeam) { project in
        Button {
          appState.setSelectedProject(project.id)
        } label: {
          HStack {
            Text(project.name)
            if appState.selectedProjectId == project.id {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    } label: {
      HStack(spacing: 6) {
        if let project = appState.selectedProject {
          ProjectDot(project: project, size: 10)
          Text(project.name)
            .lineLimit(1)
        } else {
          Image(systemName: "square.grid.2x2")
            .foregroundStyle(.secondary)
          Text("All projects")
        }
        Image(systemName: "chevron.down")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .font(.subheadline.weight(.medium))
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(
        Capsule().fill(Theme.cardBackground)
      )
      .overlay(
        Capsule().stroke(Theme.cardBorder, lineWidth: 1)
      )
    }
  }
}
