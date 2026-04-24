import SwiftUI

struct BadgeStyleModifier: ViewModifier {
  let tone: Color
  let size: BadgeSize

  func body(content: Content) -> some View {
    content
      .font(size.font.weight(.medium))
      .foregroundStyle(tone)
      .padding(.horizontal, size.horizontalPadding)
      .padding(.vertical, size.verticalPadding)
      .background(
        Capsule(style: .continuous)
          .fill(tone.opacity(0.10))
      )
      .overlay(
        Capsule(style: .continuous)
          .stroke(tone.opacity(0.30), lineWidth: 1)
      )
      .fixedSize()
  }
}

enum BadgeSize {
  case xs
  case sm
  case md

  var font: Font {
    switch self {
    case .xs: return .system(size: 10)
    case .sm: return .caption2
    case .md: return .caption
    }
  }

  var horizontalPadding: CGFloat {
    switch self {
    case .xs: return 6
    case .sm: return 8
    case .md: return 10
    }
  }

  var verticalPadding: CGFloat {
    switch self {
    case .xs: return 2
    case .sm: return 3
    case .md: return 4
    }
  }
}

extension View {
  func badgeStyle(tone: Color, size: BadgeSize = .sm) -> some View {
    modifier(BadgeStyleModifier(tone: tone, size: size))
  }
}
