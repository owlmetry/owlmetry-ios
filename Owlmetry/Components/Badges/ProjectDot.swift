import SwiftUI

struct ProjectDot: View {
  let project: Project?
  var size: CGFloat = 8

  var body: some View {
    Circle()
      .fill(ProjectColor(project: project).base)
      .frame(width: size, height: size)
      .overlay(
        Circle()
          .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
      )
  }
}
