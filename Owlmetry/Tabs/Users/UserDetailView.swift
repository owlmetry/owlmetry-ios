import Owlmetry
import SwiftUI

struct UserDetailView: View {
  let user: AppUser
  @EnvironmentObject private var appState: AppState

  private var project: Project? { appState.projectsById[user.projectId] }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        InfoGrid(items: infoItems).padding(.horizontal, 16)
        if let properties = user.properties, !properties.isEmpty {
          propertiesSection(properties)
        }
        if let apps = user.apps, !apps.isEmpty {
          appsSection(apps)
        }
      }
      .padding(.vertical, 16)
    }
    .navigationTitle("User")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .owlScreen("UserDetail")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        ProjectDot(project: project, size: 10)
        Text(project?.name ?? "—")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        UserTypeBadge(isAnonymous: user.isAnonymous, size: .sm)
        BillingBadge(properties: user.properties, size: .sm)
        AttributionBadge(properties: user.properties, size: .sm)
        Spacer()
      }
      Text(user.userId)
        .font(.footnote.monospaced())
        .foregroundStyle(.primary)
        .textSelection(.enabled)
    }
    .padding(.horizontal, 16)
  }

  private var infoItems: [InfoGrid.Item] {
    var items: [InfoGrid.Item] = [
      .init(label: "Country", value: user.lastCountryCode.map { "\(CountryFlag.emoji(for: $0)) \($0)" } ?? "—"),
      .init(label: "Version", value: user.lastAppVersion ?? "—", monospaced: true),
      .init(label: "First Seen", value: RelativeDate.string(from: user.firstSeenAt)),
      .init(label: "Last Seen", value: RelativeDate.string(from: user.lastSeenAt))
    ]
    if let claimed = user.claimedFrom {
      items.append(.init(label: "Claimed From", value: claimed, monospaced: true))
    }
    return items
  }

  private func propertiesSection(_ properties: [String: String]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Properties")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(spacing: 0) {
        ForEach(properties.keys.sorted(), id: \.self) { key in
          HStack(alignment: .top) {
            Text(key).font(.caption.monospaced()).frame(width: 140, alignment: .leading)
            Text(properties[key] ?? "")
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .textSelection(.enabled)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          Divider()
        }
      }
      .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
      .padding(.horizontal, 16)
    }
  }

  private func appsSection(_ apps: [AppUserAppInfo]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Seen in apps")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(spacing: 0) {
        ForEach(apps, id: \.id) { app in
          let appProject = app.projectId.flatMap { appState.projectsById[$0] }
          HStack(spacing: 8) {
            if let platform = app.platform {
              Text(platform.emoji)
            }
            Text(app.name).font(.footnote.weight(.medium))
            Spacer()
            if let lastSeenAt = app.lastSeenAt {
              Text(RelativeDate.shortString(from: lastSeenAt))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            if appProject != nil {
              ProjectDot(project: appProject, size: 8)
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          Divider()
        }
      }
      .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
      .padding(.horizontal, 16)
    }
  }
}
