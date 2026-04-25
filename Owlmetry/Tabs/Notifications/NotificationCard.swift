import SwiftUI

struct NotificationCard: View {
  let notification: OwlmetryNotification

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Circle()
        .fill(notification.isUnread ? Color.red : Color.secondary.opacity(0.4))
        .frame(width: 8, height: 8)
        .padding(.top, 7)

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(typeLabel(for: notification.type))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12), in: Capsule())
          Text(RelativeDate.string(from: notification.createdAt))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Text(notification.title)
          .font(.subheadline.weight(notification.isUnread ? .semibold : .regular))
          .foregroundStyle(.primary)
          .lineLimit(2)
        if let body = notification.body, !body.isEmpty {
          Text(body)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Theme.cardBackground)
    )
  }

  private func typeLabel(for type: String) -> String {
    switch type {
    case "issue.digest": return "Issue digest"
    case "feedback.new": return "Feedback"
    case "job.completed": return "Job"
    case "team.invitation": return "Invite"
    default: return type
    }
  }
}
