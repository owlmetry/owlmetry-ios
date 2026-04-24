import Charts
import SwiftUI

struct MetricOverviewChart: View {
  let aggregation: MetricAggregation

  struct PhaseBar: Identifiable {
    let id: String
    let phase: String
    let count: Int
    let color: Color
  }

  var bars: [PhaseBar] {
    var result: [PhaseBar] = []
    if let c = aggregation.startCount, c > 0 { result.append(.init(id: "start", phase: "Start", count: c, color: Theme.Phase.color(for: .start))) }
    if let c = aggregation.completeCount, c > 0 { result.append(.init(id: "complete", phase: "Complete", count: c, color: Theme.Phase.color(for: .complete))) }
    if let c = aggregation.failCount, c > 0 { result.append(.init(id: "fail", phase: "Fail", count: c, color: Theme.Phase.color(for: .fail))) }
    if let c = aggregation.cancelCount, c > 0 { result.append(.init(id: "cancel", phase: "Cancel", count: c, color: Theme.Phase.color(for: .cancel))) }
    if let c = aggregation.recordCount, c > 0 { result.append(.init(id: "record", phase: "Record", count: c, color: Theme.Phase.color(for: .record))) }
    return result
  }

  var body: some View {
    Chart(bars) { bar in
      BarMark(
        x: .value("Phase", bar.phase),
        y: .value("Count", bar.count)
      )
      .foregroundStyle(bar.color)
      .annotation(position: .top) {
        Text("\(bar.count)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .chartYAxis { AxisMarks(position: .leading) }
    .frame(height: 200)
  }
}
