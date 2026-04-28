import SwiftUI

struct MetricCard: View {
  let metric: MetricDefinition
  let project: Project?
  var stats: MetricStatsEntry? = nil

  private var total: Int? {
    guard let stats else { return nil }
    let t = stats.completeCount + stats.failCount
    return t > 0 ? t : nil
  }

  private var percent: Int? {
    guard let stats, let total else { return nil }
    return Int((Double(stats.completeCount) / Double(total) * 100).rounded())
  }

  var body: some View {
    CardShell(accent: ProjectColor(project: project).base) {
      VStack(alignment: .leading, spacing: 6) {
        Text(metric.name)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
        Text(metric.slug)
          .font(.caption2.monospaced())
          .foregroundStyle(.secondary)
          .lineLimit(1)
        if let description = metric.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
        if let stats, let total {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(stats.completeCount)/\(total)")
              .font(.subheadline.weight(.semibold))
              .monospacedDigit()
              .foregroundStyle(.primary)
            if let percent {
              Text("\(percent)%")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
          }
          .padding(.top, 2)
        }
      }
    }
  }
}
