import SwiftUI

struct UserTypeBadge: View {
  let isAnonymous: Bool
  var size: BadgeSize = .sm

  var body: some View {
    HStack(spacing: 4) {
      Text(isAnonymous ? "👻" : "👤")
      Text(isAnonymous ? "Anon" : "Real")
    }
    .badgeStyle(tone: isAnonymous ? Theme.User.anon : Theme.User.real, size: size)
  }
}
