import SwiftUI

struct DevModeBadge: View {
  var size: BadgeSize = .sm

  var body: some View {
    HStack(spacing: 4) {
      Text("🛠️")
      Text("Dev")
    }
    .badgeStyle(tone: .gray, size: size)
  }
}
