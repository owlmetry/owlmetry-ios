import SwiftUI

struct VersionBadge: View {
  let version: String?
  let latestVersion: String?
  var size: BadgeSize = .sm

  var body: some View {
    if let version, !version.isEmpty {
      Text(version)
        .monospaced()
        .badgeStyle(tone: isOnLatest ? .green : .secondary, size: size)
    } else {
      EmptyView()
    }
  }

  private var isOnLatest: Bool {
    guard let version, let latestVersion else { return false }
    return version == latestVersion
  }
}
