import SwiftUI

struct StarRow: View {
  let rating: Int
  var size: Size = .sm

  enum Size {
    case sm, lg

    var pointSize: CGFloat {
      switch self {
      case .sm: return 12
      case .lg: return 16
      }
    }
  }

  var body: some View {
    HStack(spacing: 2) {
      ForEach(1...5, id: \.self) { n in
        Image(systemName: n <= rating ? "star.fill" : "star")
          .font(.system(size: size.pointSize, weight: .medium))
          .foregroundStyle(n <= rating ? Color.orange : Color.secondary.opacity(0.4))
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(rating) out of 5 stars")
  }
}
