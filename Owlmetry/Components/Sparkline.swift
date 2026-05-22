import SwiftUI

/// Deps-free SwiftUI sparkline. Auto-scaled to [min, max] — we want the
/// *shape* of the trend, not absolute magnitude (the big number on the card
/// is already the magnitude anchor). Mirrors the web's
/// `apps/web/src/components/charts/sparkline.tsx` edge cases:
///
/// - Empty array → render nothing.
/// - All zeros → render nothing (a flat line at 0 reads as "trending down").
/// - All equal (non-zero) → flat line at vertical center.
/// - Single value → centered dot.
struct Sparkline: View {
  let values: [Double]
  var strokeWidth: CGFloat = 1

  var body: some View {
    if values.isEmpty || values.allSatisfy({ $0 == 0 }) {
      EmptyView()
    } else if values.count == 1 {
      GeometryReader { geo in
        Circle()
          .fill(Color.primary.opacity(0.35))
          .frame(width: max(2, strokeWidth * 2), height: max(2, strokeWidth * 2))
          .position(x: geo.size.width / 2, y: geo.size.height / 2)
      }
    } else {
      GeometryReader { geo in
        path(in: geo.size)
          .stroke(
            Color.primary.opacity(0.35),
            style: StrokeStyle(
              lineWidth: strokeWidth,
              lineCap: .round,
              lineJoin: .round
            )
          )
      }
    }
  }

  private func path(in size: CGSize) -> Path {
    let minV = values.min() ?? 0
    let maxV = values.max() ?? 0
    let range = maxV - minV
    let inset = strokeWidth / 2
    let yTop = inset
    let yBottom = size.height - inset
    let xLeft: CGFloat = 0
    let xRight = size.width

    return Path { p in
      for i in values.indices {
        let x = xLeft + CGFloat(i) / CGFloat(values.count - 1) * (xRight - xLeft)
        // Flat at vertical center when all values equal — avoids
        // divide-by-zero and avoids drawing along the bottom edge (which
        // reads as "trending down to zero" visually).
        let y: CGFloat
        if range == 0 {
          y = (yTop + yBottom) / 2
        } else {
          y = yBottom - CGFloat((values[i] - minV) / range) * (yBottom - yTop)
        }
        if i == 0 {
          p.move(to: CGPoint(x: x, y: y))
        } else {
          p.addLine(to: CGPoint(x: x, y: y))
        }
      }
    }
  }
}
