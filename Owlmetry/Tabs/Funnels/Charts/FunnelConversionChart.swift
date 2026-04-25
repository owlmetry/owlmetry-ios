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
          x: .value("Users", step.uniqueUsers),
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
    "\(step.stepIndex + 1). \(step.stepName)"
  }

  private func annotation(for step: FunnelStepAnalytics) -> String {
    if let rate = step.conversionFromPrevious {
      return "\(step.uniqueUsers) · \(Int(rate * 100))%"
    }
    return "\(step.uniqueUsers)"
  }
}
