import SwiftUI

struct StatCard: View {
  let label: String
  let systemImage: String
  let value: String
  var secondary: String? = nil
  var delta: Int? = nil
  var isLoading: Bool = false
  /// Sparkline series. `nil` or empty renders a transparent slot of the
  /// same height as a drawn chart, so every card on the dashboard stays
  /// uniformly tall regardless of which row it lands on.
  var sparklineValues: [Double]? = nil
  /// Dense variant for widget grids (medium/large) where many cards share a
  /// tight space. Shrinks the value font, slot heights, and padding. The
  /// default (`false`) preserves the dashboard's original layout exactly.
  var compact: Bool = false

  private var labelSize: CGFloat { compact ? 9 : 10 }
  private var valueSize: CGFloat { compact ? 22 : 34 }
  private var secondarySize: CGFloat { compact ? 11 : 13 }
  private var contentSlotHeight: CGFloat { compact ? 26 : 42 }
  private var sparklineSlotHeight: CGFloat { compact ? 20 : 42 }
  private var valueTopPadding: CGFloat { compact ? 6 : 14 }
  private var outerHorizontalPadding: CGFloat { compact ? 12 : 16 }
  private var outerTopPadding: CGFloat { compact ? 12 : 16 }

  var body: some View {
    // VStack `spacing: 0` so we can hand-pick the gaps: 14pt between header
    // and value (matches the old default), but only 1pt between value and
    // chart — chart cards want every spare pixel for vertical resolution.
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(label.uppercased())
          .font(.system(size: labelSize, weight: .semibold))
          .tracking(0.8)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        Spacer(minLength: 0)
        Image(systemName: systemImage)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
      }
      Group {
        if isLoading {
          ProgressView()
        } else {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(value)
              .font(.system(size: valueSize, weight: .semibold, design: .default))
              .monospacedDigit()
              .lineLimit(1)
              .minimumScaleFactor(0.4)
              .foregroundStyle(.primary)
            if let secondary {
              Text(secondary)
                .font(.system(size: secondarySize, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.secondary)
            }
            DeltaText(delta: delta, tone: .muted)
          }
        }
      }
      .frame(height: contentSlotHeight, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, valueTopPadding)
      // Sparkline slot is always present (transparent when empty) so cards
      // share an identical intrinsic height — the grid never has to stretch
      // chartless cards to match chart-bearing siblings. Zero bottom padding
      // lets the chart's y-axis floor sit on the card's bottom border.
      Sparkline(values: sparklineValues ?? [])
        .frame(height: sparklineSlotHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, outerHorizontalPadding)
    .padding(.top, outerTopPadding)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Theme.cardBackground)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Theme.cardBorder, lineWidth: 1)
    )
  }
}
