import SwiftUI

struct StatCard: View {
  let label: String
  let systemImage: String
  let value: String
  var secondary: String? = nil
  var delta: Int? = nil
  var isLoading: Bool = false
  /// When non-nil, a small sparkline is rendered at the bottom of the card.
  /// An empty array reserves the slot (keeps card height stable on cards
  /// that *will* eventually have data) without drawing anything.
  var sparklineValues: [Double]? = nil

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
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
      if let sparklineValues {
        Sparkline(values: sparklineValues)
          .frame(height: 22)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, sparklineValues == nil ? 16 : 10)
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
