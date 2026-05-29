import SwiftUI
import WidgetKit

extension DashboardMetric {
  /// Deep link opened when the user taps this metric in a widget.
  var widgetURL: URL {
    URL(string: "owlmetry://\(deepLinkPath)") ?? URL(string: "owlmetry://dashboard")!
  }
}

/// Wraps the shared `StatCard` for widget use, pulling the strings out of a
/// `MetricValue`. `compact` drives the dense grid variant.
struct WidgetStatCardView: View {
  let metric: DashboardMetric
  let value: MetricValue
  var compact: Bool = false

  var body: some View {
    StatCard(
      label: metric.label,
      systemImage: metric.systemImage,
      value: value.value,
      secondary: value.secondary,
      delta: value.delta,
      sparklineValues: value.sparkline.isEmpty ? nil : value.sparkline,
      compact: compact
    )
  }
}

/// Small / medium single-stat layout — one full-size card.
struct SingleStatWidgetView: View {
  let entry: DashboardWidgetEntry

  var body: some View {
    if !entry.signedIn {
      WidgetSignedOutView()
    } else if let metric = entry.metrics.first {
      WidgetStatCardView(metric: metric, value: entry.value(for: metric))
    } else {
      WidgetSignedOutView()
    }
  }
}

/// 2-column grid of compact cards — used by both the quad (medium) and the
/// large widget. Each cell deep-links to its section.
struct MetricGridWidgetView: View {
  let entry: DashboardWidgetEntry

  private let columns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8),
  ]

  var body: some View {
    if !entry.signedIn {
      WidgetSignedOutView()
    } else {
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(entry.metrics, id: \.self) { metric in
          Link(destination: metric.widgetURL) {
            WidgetStatCardView(metric: metric, value: entry.value(for: metric), compact: true)
          }
        }
      }
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
