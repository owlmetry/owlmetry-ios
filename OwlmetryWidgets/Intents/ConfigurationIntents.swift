import AppIntents

/// Single-stat widget: pick one metric. Project scope is the app's current team
/// (read from the shared store), so there's no project parameter.
struct SingleStatConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Single Stat" }
  static var description: IntentDescription { "Show one metric from your dashboard." }

  @Parameter(title: "Metric", default: .openIssues)
  var metric: MetricChoice
}

/// 2×2 widget: pick the four metrics. Defaults to the headline four.
struct QuadConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Four Metrics" }
  static var description: IntentDescription { "Show four metrics in a grid." }

  @Parameter(title: "Top Left", default: .openIssues)
  var slot1: MetricChoice
  @Parameter(title: "Top Right", default: .events)
  var slot2: MetricChoice
  @Parameter(title: "Bottom Left", default: .users)
  var slot3: MetricChoice
  @Parameter(title: "Bottom Right", default: .sessions)
  var slot4: MetricChoice

  var metrics: [DashboardMetric] {
    [slot1, slot2, slot3, slot4].map(\.metric)
  }
}

/// Large widget: pick a preset set of metrics.
struct LargeConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Dashboard" }
  static var description: IntentDescription { "Show a set of metrics from your dashboard." }

  @Parameter(title: "Preset", default: .overview)
  var preset: PresetChoice
}
