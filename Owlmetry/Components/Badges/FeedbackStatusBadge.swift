import SwiftUI

struct FeedbackStatusBadge: View {
  let status: FeedbackStatus
  var size: BadgeSize = .sm

  var body: some View {
    HStack(spacing: 4) {
      Text(status.emoji)
      Text(status.displayName)
    }
    .badgeStyle(tone: Theme.Status.color(for: status), size: size)
  }
}
