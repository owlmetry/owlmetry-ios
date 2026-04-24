import SwiftUI

struct AppBadge: View {
  let app: AppModel?
  let project: Project?
  var size: BadgeSize = .sm
  var showPlatform: Bool = true

  var body: some View {
    let projectColor = ProjectColor(project: project)
    HStack(spacing: 4) {
      if let platform = app?.platform, showPlatform {
        Text(platform.emoji)
      }
      Text(app?.name ?? "—")
        .lineLimit(1)
    }
    .badgeStyle(tone: projectColor.base, size: size)
  }
}

struct AppPillRow: View {
  let apps: [AppModel]
  let projectsById: [String: Project]
  var size: BadgeSize = .sm

  var body: some View {
    if apps.isEmpty {
      EmptyView()
    } else {
      HStack(spacing: 4) {
        ForEach(apps.prefix(3)) { app in
          AppBadge(app: app, project: projectsById[app.projectId], size: size)
        }
        if apps.count > 3 {
          Text("+\(apps.count - 3)")
            .badgeStyle(tone: .gray, size: size)
        }
      }
    }
  }
}
