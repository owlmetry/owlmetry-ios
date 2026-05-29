import SwiftUI

/// How a `StatCard` sizes and decorates itself.
enum StatCardStyle {
  /// Dashboard grid: fixed-height slots + card chrome so every card in the
  /// adaptive grid is uniformly tall. Intrinsically sized (does not fill).
  case dashboard
  /// A widget showing a single card: no border/background (the widget's own
  /// container background shows through — avoids a card-on-a-card look) and
  /// fills the whole widget, with the chart expanding into the free space.
  case widgetSolo
  /// A tile inside a widget grid: keeps card chrome (so tiles read as distinct
  /// cards) and fills its grid cell, with the chart expanding to fill.
  case widgetTile

  var hasChrome: Bool { self != .widgetSolo }
  /// Fill the container instead of sizing to content — lets widget cards adapt
  /// to whatever height the grid hands them.
  var fillsContainer: Bool { self != .dashboard }
  var isCompact: Bool { self == .widgetTile }

  var labelSize: CGFloat { isCompact ? 9 : 10 }
  var valueSize: CGFloat { isCompact ? 22 : 34 }
  var secondarySize: CGFloat { isCompact ? 11 : 13 }
  var valueTopPadding: CGFloat { isCompact ? 6 : 14 }
  /// Outer padding. Dashboard keeps its asymmetric padding (top 16, no bottom —
  /// the chart floor sits on the bottom border); widgets pad all sides.
  var horizontalPadding: CGFloat { isCompact ? 12 : (self == .dashboard ? 16 : 14) }
  var topPadding: CGFloat { isCompact ? 12 : (self == .dashboard ? 16 : 14) }
  var bottomPadding: CGFloat { self == .dashboard ? 0 : (isCompact ? 12 : 14) }

  /// Dashboard pins both the value row and the chart to fixed heights so cards
  /// line up; widgets leave the value row intrinsic and let the chart flex.
  var fixedContentHeight: CGFloat? { self == .dashboard ? 42 : nil }
  var fixedSparklineHeight: CGFloat? { self == .dashboard ? 42 : nil }
}

struct StatCard: View {
  let label: String
  let systemImage: String
  let value: String
  var secondary: String? = nil
  var delta: Int? = nil
  var isLoading: Bool = false
  /// Sparkline series. `nil` or empty renders a transparent slot so chartless
  /// cards keep the same shape as chart-bearing siblings.
  var sparklineValues: [Double]? = nil
  var style: StatCardStyle = .dashboard

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      valueRow
        .frame(height: style.fixedContentHeight, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, style.valueTopPadding)
      // Dashboard pins the chart to a fixed slot; widgets let it expand into
      // all remaining vertical space so the card fills its container and the
      // chart is always as tall as it can be.
      Sparkline(values: sparklineValues ?? [])
        .frame(height: style.fixedSparklineHeight)
        .frame(maxWidth: .infinity, maxHeight: style.fillsContainer ? .infinity : nil, alignment: .leading)
        .padding(.top, 1)
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: style.fillsContainer ? .infinity : nil,
      alignment: .topLeading
    )
    .padding(.horizontal, style.horizontalPadding)
    .padding(.top, style.topPadding)
    .padding(.bottom, style.bottomPadding)
    .background(cardBackground)
    .overlay(cardBorder)
  }

  private var header: some View {
    HStack(alignment: .top) {
      Text(label.uppercased())
        .font(.system(size: style.labelSize, weight: .semibold))
        .tracking(0.8)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Spacer(minLength: 0)
      Image(systemName: systemImage)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder private var valueRow: some View {
    if isLoading {
      ProgressView()
    } else {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text(value)
          .font(.system(size: style.valueSize, weight: .semibold, design: .default))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.4)
          .foregroundStyle(.primary)
        if let secondary {
          Text(secondary)
            .font(.system(size: style.secondarySize, weight: .medium))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(.secondary)
        }
        DeltaText(delta: delta, tone: .muted)
      }
    }
  }

  @ViewBuilder private var cardBackground: some View {
    if style.hasChrome {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Theme.cardBackground)
    }
  }

  @ViewBuilder private var cardBorder: some View {
    if style.hasChrome {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Theme.cardBorder, lineWidth: 1)
    }
  }
}
