import AppIntents
import Foundation
import WidgetKit

/// One rendered widget snapshot: the ordered metrics to show, their loaded
/// values (nil until loaded / on failure), and whether the user is signed in.
struct DashboardWidgetEntry: TimelineEntry {
  let date: Date
  let metrics: [DashboardMetric]
  let snapshot: DashboardSnapshot?
  let signedIn: Bool

  func value(for metric: DashboardMetric) -> MetricValue {
    snapshot?.value(for: metric) ?? .dash
  }
}

/// Counts are 24h windows, so a ~35-minute cadence is plenty and stays well
/// within WidgetKit's per-widget refresh budget. The app additionally calls
/// `WidgetCenter.reloadAllTimelines()` on scope changes for immediacy.
enum WidgetRefresh {
  static func nextDate() -> Date {
    Date().addingTimeInterval(35 * 60)
  }
}

/// Shared loading used by every provider: reads scope from the App Group,
/// gates on the shared-Keychain token, and calls the same loader the app uses.
enum WidgetDataLoader {
  static func entry(for metrics: [DashboardMetric], includeSparklines: Bool) async -> DashboardWidgetEntry {
    let signedIn = KeychainService.token() != nil
    guard signedIn, let teamId = WidgetSharedStore.teamId else {
      return DashboardWidgetEntry(date: Date(), metrics: metrics, snapshot: nil, signedIn: signedIn)
    }
    let snapshot = await DashboardSnapshotLoader.load(
      teamId: teamId,
      projectId: nil,  // widgets are team-total
      dataMode: WidgetSharedStore.dataMode,
      metrics: Set(metrics),
      includeSparklines: includeSparklines
    )
    return DashboardWidgetEntry(date: Date(), metrics: metrics, snapshot: snapshot, signedIn: true)
  }

  static func placeholder(for metrics: [DashboardMetric]) -> DashboardWidgetEntry {
    DashboardWidgetEntry(date: Date(), metrics: metrics, snapshot: nil, signedIn: true)
  }
}

// MARK: - Providers

struct SingleStatProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> DashboardWidgetEntry {
    WidgetDataLoader.placeholder(for: [.openIssues])
  }

  func snapshot(for configuration: SingleStatConfigurationIntent, in context: Context) async -> DashboardWidgetEntry {
    await WidgetDataLoader.entry(for: [configuration.metric.metric], includeSparklines: true)
  }

  func timeline(for configuration: SingleStatConfigurationIntent, in context: Context) async -> Timeline<DashboardWidgetEntry> {
    let entry = await WidgetDataLoader.entry(for: [configuration.metric.metric], includeSparklines: true)
    return Timeline(entries: [entry], policy: .after(WidgetRefresh.nextDate()))
  }
}

struct QuadProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> DashboardWidgetEntry {
    WidgetDataLoader.placeholder(for: [.openIssues, .events, .users, .sessions])
  }

  func snapshot(for configuration: QuadConfigurationIntent, in context: Context) async -> DashboardWidgetEntry {
    await WidgetDataLoader.entry(for: configuration.metrics, includeSparklines: true)
  }

  func timeline(for configuration: QuadConfigurationIntent, in context: Context) async -> Timeline<DashboardWidgetEntry> {
    let entry = await WidgetDataLoader.entry(for: configuration.metrics, includeSparklines: true)
    return Timeline(entries: [entry], policy: .after(WidgetRefresh.nextDate()))
  }
}

struct LargeProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> DashboardWidgetEntry {
    WidgetDataLoader.placeholder(for: PresetChoice.overview.metrics)
  }

  func snapshot(for configuration: LargeConfigurationIntent, in context: Context) async -> DashboardWidgetEntry {
    await WidgetDataLoader.entry(for: configuration.preset.metrics, includeSparklines: false)
  }

  func timeline(for configuration: LargeConfigurationIntent, in context: Context) async -> Timeline<DashboardWidgetEntry> {
    let entry = await WidgetDataLoader.entry(for: configuration.preset.metrics, includeSparklines: false)
    return Timeline(entries: [entry], policy: .after(WidgetRefresh.nextDate()))
  }
}
