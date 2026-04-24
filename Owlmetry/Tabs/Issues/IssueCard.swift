import SwiftUI

struct IssueCard: View {
  let issue: Issue
  let app: AppModel?
  let project: Project?

  var body: some View {
    CardShell(accent: ProjectColor(project: project).base) {
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: 8) {
          Text(issue.title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          HStack(spacing: 6) {
            if app != nil {
              AppBadge(app: app, project: project, size: .xs)
            }
            if let version = issue.lastSeenAppVersion {
              VersionBadge(version: version, latestVersion: app?.latestAppVersion, size: .xs)
            }
            if issue.isDev == true {
              DevModeBadge(size: .xs)
            }
          }
          HStack(spacing: 10) {
            Label("\(issue.occurrenceCount)", systemImage: "ladybug")
            Label("\(issue.uniqueUserCount)", systemImage: "person.2")
            Label(RelativeDate.shortString(from: issue.lastSeenAt), systemImage: "clock")
          }
          .font(.caption2)
          .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
    }
  }
}
