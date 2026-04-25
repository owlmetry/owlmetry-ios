import SwiftUI

struct UserCard: View {
  let user: AppUser
  let apps: [AppModel]
  let projectsById: [String: Project]

  var body: some View {
    let project = projectsById[user.projectId]
    NavigableCard(accent: ProjectColor(project: project).base) {
      HStack(spacing: 8) {
        UserTypeBadge(isAnonymous: user.isAnonymous, size: .xs)
        Text(String(user.userId.prefix(16)))
          .font(.caption2.monospaced())
          .lineLimit(1)
          .truncationMode(.tail)
        Spacer()
        if let country = user.lastCountryCode {
          CountryCell(code: country, showCode: false)
        }
      }
      if !apps.isEmpty {
        AppPillRow(apps: apps, projectsById: projectsById, size: .xs)
      }
      HStack(spacing: 6) {
        if let version = user.lastAppVersion {
          VersionBadge(version: version, latestVersion: nil, size: .xs)
        }
        BillingBadge(properties: user.properties, size: .xs)
        AttributionBadge(properties: user.properties, size: .xs)
      }
      HStack(spacing: 10) {
        Label("First \(RelativeDate.shortString(from: user.firstSeenAt))", systemImage: "arrow.up.right")
        if let lastSeenAt = user.lastSeenAt {
          Label("Last \(RelativeDate.shortString(from: lastSeenAt))", systemImage: "clock")
        }
      }
      .font(.caption2)
      .foregroundStyle(.secondary)
    }
  }
}
