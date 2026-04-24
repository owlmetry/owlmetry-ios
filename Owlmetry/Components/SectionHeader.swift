import SwiftUI

struct SectionHeader: View {
  let title: String
  var count: Int? = nil
  var emoji: String? = nil
  var tone: Color = .secondary

  var body: some View {
    HStack(spacing: 8) {
      if let emoji {
        Text(emoji)
      }
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
      if let count {
        Text("\(count)")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(tone)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(
            Capsule().fill(tone.opacity(0.15))
          )
      }
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
}
