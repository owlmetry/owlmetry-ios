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

  private static let sparklineSlotHeight: CGFloat = 42

  var body: some View {
    // VStack `spacing: 0` so we can hand-pick the gaps: 14pt between header
    // and value (matches the old default), but only 1pt between value and
    // chart — chart cards want every spare pixel for vertical resolution.
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(label.uppercased())
          .font(.system(size: 10, weight: .semibold))
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
              .font(.system(size: 34, weight: .semibold, design: .default))
              .monospacedDigit()
              .lineLimit(1)
              .minimumScaleFactor(0.4)
              .foregroundStyle(.primary)
            if let secondary {
              Text(secondary)
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.secondary)
            }
            DeltaText(delta: delta, tone: .muted)
          }
        }
      }
      .frame(height: 42, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 14)
      // Sparkline slot is always present (transparent when empty) so cards
      // share an identical intrinsic height — the grid never has to stretch
      // chartless cards to match chart-bearing siblings. Zero bottom padding
      // lets the chart's y-axis floor sit on the card's bottom border.
      Sparkline(values: sparklineValues ?? [])
        .frame(height: Self.sparklineSlotHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.top, 16)
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
