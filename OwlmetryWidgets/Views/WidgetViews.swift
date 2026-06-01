import SwiftUI
import WidgetKit

extension DashboardMetric {
  /// Deep link opened when the user taps this metric in a widget.
  var widgetURL: URL {
    URL(string: "owlmetry://\(deepLinkPath)") ?? URL(string: "owlmetry://dashboard")!
  }
}

/// Wraps the shared `StatCard` for widget use, pulling the strings out of a
/// `MetricValue`.
struct WidgetStatCardView: View {
  let metric: DashboardMetric
  let value: MetricValue
  var windowHours: Int
  var style: StatCardStyle

  var body: some View {
    StatCard(
      label: metric.label(windowHours: windowHours),
      systemImage: metric.systemImage,
      value: value.value,
      secondary: value.secondary,
      delta: value.delta,
      sparklineValues: value.sparkline.isEmpty ? nil : value.sparkline,
      style: style
    )
  }
}

/// Small / medium single-stat layout — one borderless card filling the widget.
struct SingleStatWidgetView: View {
  let entry: DashboardWidgetEntry

  var body: some View {
    if !entry.signedIn {
      WidgetSignedOutView()
    } else if let metric = entry.metrics.first {
      WidgetStatCardView(metric: metric, value: entry.value(for: metric), windowHours: entry.windowHours, style: .widgetSolo)
    } else {
      WidgetSignedOutView()
    }
  }
}

/// 2-column grid of tile cards — used by both the quad (medium) and the large
/// widget. Built from nested stacks (not LazyVGrid) so every row gets an exact
/// equal share of the container height: 6 / 8 / 10 cards all fill the widget
/// with no clipping or dead space, and each card's chart flexes to fit.
struct MetricGridWidgetView: View {
  let entry: DashboardWidgetEntry

  private let columns = 2
  private let spacing: CGFloat = 8

  private var rows: [[DashboardMetric]] {
    stride(from: 0, to: entry.metrics.count, by: columns).map {
      Array(entry.metrics[$0..<min($0 + columns, entry.metrics.count)])
    }
  }

  var body: some View {
    if !entry.signedIn {
      WidgetSignedOutView()
    } else {
      // Equal-height rows via maxHeight:.infinity on each row — SwiftUI divides
      // the free space evenly, so the grid fills the widget for any card count.
      VStack(spacing: spacing) {
        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
          HStack(spacing: spacing) {
            ForEach(row, id: \.self) { metric in
              Link(destination: metric.widgetURL) {
                WidgetStatCardView(metric: metric, value: entry.value(for: metric), windowHours: entry.windowHours, style: .widgetTile)
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
            }
            // Pad a trailing single-card row so it doesn't stretch full width.
            if row.count < columns {
              ForEach(0..<(columns - row.count), id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
              }
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

/// Shown when there is no shared auth token — tapping opens the app to sign in.
struct WidgetSignedOutView: View {
  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: "person.crop.circle.badge.questionmark")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("Sign in to Owlmetry")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
