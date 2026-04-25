import SwiftUI

struct NavigableCard<Content: View>: View {
  var accent: Color? = nil
  var contentSpacing: CGFloat = 8
  @ViewBuilder var content: () -> Content

  var body: some View {
    CardShell(accent: accent) {
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: contentSpacing) {
          content()
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
    }
  }
}
