import SwiftUI

/// Circular avatar with initials + a small red unread badge in the top-right.
/// Used in the Dashboard nav bar as the entry point to ProfileView.
struct ProfileAvatarButton: View {
  let initials: String
  let unread: Int

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Circle()
        .fill(Color.accentColor.opacity(0.15))
        .frame(width: 30, height: 30)
        .overlay(
          Text(initials)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
        )

      if unread > 0 {
        Text(unread > 99 ? "99+" : "\(unread)")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(.white)
          .padding(.horizontal, 4)
          .frame(minWidth: 16, minHeight: 16)
          .background(Color.red, in: Capsule())
          .overlay(
            Capsule().stroke(Color(.systemBackground), lineWidth: 1.5)
          )
          .offset(x: 4, y: -4)
      }
    }
  }
}
