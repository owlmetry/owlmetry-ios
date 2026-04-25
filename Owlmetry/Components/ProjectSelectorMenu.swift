import SwiftUI
import UIKit

struct ProjectSelectorMenu: View {
  @EnvironmentObject private var appState: AppState

  private var projectSelection: Binding<String?> {
    Binding(
      get: { appState.selectedProjectId },
      set: { appState.setSelectedProject($0) }
    )
  }

  var body: some View {
    Menu {
      Picker("Project", selection: projectSelection) {
        Label {
          Text("All projects")
        } icon: {
          Image(systemName: "square.grid.2x2")
        }
        .tag(String?.none)

        ForEach(appState.projectsForCurrentTeam) { project in
          Label {
            Text(project.name)
          } icon: {
            Image(uiImage: Self.coloredDot(hex: project.color))
          }
          .tag(Optional(project.id))
        }
      }
      .pickerStyle(.inline)
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
        Text("(\(appState.projectsForCurrentTeam.count))")
          .foregroundStyle(.secondary)
        Image(systemName: "chevron.down")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .font(.subheadline.weight(.medium))
    }
  }

  private static func coloredDot(hex: String) -> UIImage {
    let color = UIColor(ProjectColor(hex: hex).base)
    let size = CGSize(width: 14, height: 14)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
      color.setFill()
      ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
    }
    return image.withRenderingMode(.alwaysOriginal)
  }
}
