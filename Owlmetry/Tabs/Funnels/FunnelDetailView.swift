import Owlmetry
import SwiftUI

struct FunnelDetailView: View {
  let funnel: FunnelDefinition
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = FunnelDetailViewModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        rangePicker
        if let analytics = viewModel.analytics {
          summaryRow(analytics)
          chartSection(analytics)
          stepsTable(analytics)
        } else if viewModel.isLoading {
          LoadingState()
        } else if let message = viewModel.errorMessage {
          ErrorState(message: message) { Task { await reload() } }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .navigationTitle(funnel.name)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: "\(funnel.id)|\(viewModel.range.rawValue)|\(appState.dataMode.rawValue)") {
      await reload()
    }
    .toolbar(.hidden, for: .tabBar)
    .owlScreen("FunnelDetail")
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    await viewModel.load(
      slug: funnel.slug,
      teamId: teamId,
      projectId: funnel.projectId,
      dataMode: appState.dataMode
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(funnel.slug)
        .font(.caption2.monospaced())
        .foregroundStyle(.secondary)
      if let description = funnel.description, !description.isEmpty {
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

  private func summaryRow(_ analytics: FunnelAnalytics) -> some View {
    HStack(spacing: 10) {
      summaryPill(label: "Starts", text: analytics.totalStarts.map { "\($0)" } ?? "—", color: .blue)
      summaryPill(label: "Completions", text: analytics.totalCompletions.map { "\($0)" } ?? "—", color: .green)
      summaryPill(label: "Conversion", text: analytics.conversionRate.map { "\(Int($0 * 100))%" } ?? "—", color: .accentColor)
    }
  }

  private func summaryPill(label: String, text: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label.uppercased())
        .font(.system(size: 9, weight: .semibold))
        .tracking(0.6)
        .foregroundStyle(.secondary)
      Text(text)
        .font(.title3.monospacedDigit().weight(.semibold))
        .foregroundStyle(color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
  }

  private func chartSection(_ analytics: FunnelAnalytics) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Conversion").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
      FunnelConversionChart(analytics: analytics)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
    }
  }

  private func stepsTable(_ analytics: FunnelAnalytics) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Steps").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
      VStack(spacing: 0) {
        ForEach(analytics.steps) { step in
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(step.stepName).font(.footnote.weight(.medium))
              HStack(spacing: 6) {
                Label("\(step.uniqueUsers)", systemImage: "person.2")
                if step.dropOffCount > 0 {
                  Label("\(step.dropOffCount) drop off", systemImage: "arrow.down.right")
                    .foregroundStyle(.orange)
                }
              }
              .font(.caption2)
              .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(step.percentage))%")
              .font(.footnote.monospacedDigit().weight(.semibold))
              .foregroundStyle(.primary)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          Divider()
        }
      }
      .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
    }
  }
}
