import Charts
import SwiftUI

struct DurationPercentileChart: View {
  let aggregation: MetricAggregation

  struct Bucket: Identifiable {
    let id: String
    let label: String
    let ms: Double
  }

  var buckets: [Bucket] {
    var result: [Bucket] = []
    if let v = aggregation.durationAvgMs { result.append(.init(id: "avg", label: "Avg", ms: v)) }
    if let v = aggregation.durationP50Ms { result.append(.init(id: "p50", label: "p50", ms: v)) }
    if let v = aggregation.durationP95Ms { result.append(.init(id: "p95", label: "p95", ms: v)) }
    if let v = aggregation.durationP99Ms { result.append(.init(id: "p99", label: "p99", ms: v)) }
    return result
  }

  var body: some View {
    if buckets.isEmpty {
      EmptyView()
    } else {
      Chart(buckets) { bucket in
        BarMark(
          x: .value("Bucket", bucket.label),
          y: .value("ms", bucket.ms)
        )
        .foregroundStyle(Color.accentColor.gradient)
        .annotation(position: .top) {
          Text("\(Int(bucket.ms)) ms")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .chartYAxis { AxisMarks(position: .leading) }
      .frame(height: 200)
    }
  }
}
