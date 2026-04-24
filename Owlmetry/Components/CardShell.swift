import SwiftUI

struct CardShell<Content: View>: View {
  var accent: Color? = nil
  var padding: CGFloat = 14
  @ViewBuilder var content: () -> Content

  var body: some View {
    HStack(spacing: 0) {
      if let accent {
        Rectangle()
          .fill(accent)
          .frame(width: 3)
      }
      content()
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Theme.cardBackground)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Theme.cardBorder, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}
