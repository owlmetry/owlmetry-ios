import SwiftUI
import WidgetKit

/// Small / medium: one configurable metric.
struct OwlmetrySingleStatWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "OwlmetrySingleStat",
      intent: SingleStatConfigurationIntent.self,
      provider: SingleStatProvider()
    ) { entry in
      SingleStatWidgetView(entry: entry)
        .containerBackground(.background, for: .widget)
        .widgetURL(entry.metrics.first?.widgetURL)
    }
    .configurationDisplayName("Owlmetry Stat")
    .description("A single metric at a glance.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

/// Medium: four configurable metrics in a 2×2 grid.
struct OwlmetryQuadWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "OwlmetryQuad",
      intent: QuadConfigurationIntent.self,
      provider: QuadProvider()
    ) { entry in
      MetricGridWidgetView(entry: entry)
        .containerBackground(.background, for: .widget)
    }
    .configurationDisplayName("Owlmetry Grid")
    .description("Four metrics in a grid.")
    .supportedFamilies([.systemMedium])
  }
}

/// Large: a preset set of metrics.
struct OwlmetryDashboardWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "OwlmetryDashboard",
      intent: LargeConfigurationIntent.self,
      provider: LargeProvider()
    ) { entry in
      MetricGridWidgetView(entry: entry)
        .containerBackground(.background, for: .widget)
    }
    .configurationDisplayName("Owlmetry Dashboard")
    .description("A set of metrics from your dashboard.")
    .supportedFamilies([.systemLarge])
  }
}
