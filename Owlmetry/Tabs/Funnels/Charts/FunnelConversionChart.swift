import Charts
import SwiftUI

struct FunnelConversionChart: View {
  let analytics: FunnelAnalytics

  var body: some View {
    if analytics.steps.isEmpty {
      EmptyView()
    } else {
      Chart(analytics.steps) { step in
        BarMark(
          x: .value("Users", step.uniqueUsers ?? step.count ?? 0),
          y: .value("Step", displayName(for: step))
        )
        .foregroundStyle(Color.accentColor.gradient)
        .annotation(position: .trailing) {
          Text(annotation(for: step))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .chartYAxis { AxisMarks(position: .leading) }
      .frame(height: CGFloat(analytics.steps.count) * 44 + 24)
    }
  }

  private func displayName(for step: FunnelStepAnalytics) -> String {
    if let order = step.order { return "\(order + 1). \(step.name)" }
    return step.name
  }

  private func annotation(for step: FunnelStepAnalytics) -> String {
    let users = step.uniqueUsers ?? step.count ?? 0
    if let rate = step.conversionFromPrevious {
      return "\(users) · \(Int(rate * 100))%"
    }
    return "\(users)"
  }
}
