import Owlmetry
import SwiftUI

struct MetricDetailView: View {
  let metric: MetricDefinition
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = MetricDetailViewModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        header
        rangePicker
        if let aggregation = viewModel.aggregation {
          summaryRow(aggregation)
          overviewSection(aggregation)
          durationSection(aggregation)
        } else if viewModel.isLoading {
          LoadingState()
        } else if let message = viewModel.errorMessage {
          ErrorState(message: message) { Task { await reload() } }
        }
        if !viewModel.events.isEmpty {
          recentEvents
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .navigationTitle(metric.name)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: "\(metric.id)|\(viewModel.range.rawValue)|\(appState.dataMode.rawValue)") {
      await reload()
    }
    .toolbar(.hidden, for: .tabBar)
    .owlScreen("MetricDetail")
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    await viewModel.load(
      slug: metric.slug,
      teamId: teamId,
      projectId: metric.projectId,
      dataMode: appState.dataMode
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(metric.slug)
        .font(.caption2.monospaced())
        .foregroundStyle(.secondary)
      if let description = metric.description, !description.isEmpty {
        Text(description)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var rangePicker: some View {
    Picker("Range", selection: $viewModel.range) {
      ForEach(MetricTimeRange.allCases) { range in
        Text(range.displayName).tag(range)
      }
    }
    .pickerStyle(.segmented)
  }

  @ViewBuilder
  private func summaryRow(_ aggregation: MetricAggregation) -> some View {
    HStack(spacing: 10) {
      summaryPill(label: "Start", value: aggregation.startCount, color: Theme.Phase.color(for: .start))
      summaryPill(label: "Complete", value: aggregation.completeCount, color: Theme.Phase.color(for: .complete))
      summaryPill(label: "Fail", value: aggregation.failCount, color: Theme.Phase.color(for: .fail))
      if let rate = aggregation.successRate {
        summaryPill(label: "Success", value: nil, text: "\(Int(rate))%", color: .green)
      }
    }
  }

  private func summaryPill(label: String, value: Int?, text: String? = nil, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label.uppercased())
        .font(.system(size: 9, weight: .semibold))
        .tracking(0.6)
        .foregroundStyle(.secondary)
      Text(text ?? (value.map { "\($0)" } ?? "—"))
        .font(.title3.monospacedDigit().weight(.semibold))
        .foregroundStyle(color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
  }

  @ViewBuilder
  private func overviewSection(_ aggregation: MetricAggregation) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Overview").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
      MetricOverviewChart(aggregation: aggregation)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
    }
  }

  @ViewBuilder
  private func durationSection(_ aggregation: MetricAggregation) -> some View {
    if aggregation.durationAvgMs != nil || aggregation.durationP50Ms != nil {
      VStack(alignment: .leading, spacing: 8) {
        Text("Duration").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        DurationPercentileChart(aggregation: aggregation)
          .padding(12)
          .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
      }
    }
  }

  private var recentEvents: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Recent events").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
      VStack(spacing: 0) {
        ForEach(viewModel.events) { event in
          HStack(spacing: 10) {
            MetricPhaseBadge(phase: event.phase, size: .xs)
            if let duration = event.durationMs {
              Text("\(Int(duration)) ms").font(.caption2.monospacedDigit())
            }
            Spacer()
            Text(RelativeDate.shortString(from: event.timestamp))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          Divider()
        }
      }
      .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
    }
  }
}
