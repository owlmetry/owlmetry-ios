import SwiftUI

struct StatusTabBar<Tag: Hashable>: View {
  struct Item: Identifiable {
    let tag: Tag
    let label: String
    let emoji: String
    let count: Int
    let tone: Color
    var id: Tag { tag }
  }

  let items: [Item]
  @Binding var selection: Tag

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(items) { item in
          pill(for: item)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
    }
  }

  private func pill(for item: Item) -> some View {
    let isSelected = item.tag == selection
    return Button {
      Haptics.play(.light)
      selection = item.tag
    } label: {
      HStack(spacing: 6) {
        Text(item.emoji)
        Text(item.label)
          .font(.subheadline.weight(isSelected ? .semibold : .medium))
        Text("\(item.count)")
          .font(.caption2.weight(.semibold))
          .monospacedDigit()
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Capsule().fill(isSelected ? item.tone.opacity(0.25) : Color(.quaternarySystemFill)))
      }
      .foregroundStyle(isSelected ? item.tone : .primary)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(isSelected ? item.tone.opacity(0.15) : Color(.tertiarySystemFill))
      )
      .overlay(
        Capsule()
          .strokeBorder(isSelected ? item.tone.opacity(0.4) : Color.clear, lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(item.label), \(item.count)")
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}
