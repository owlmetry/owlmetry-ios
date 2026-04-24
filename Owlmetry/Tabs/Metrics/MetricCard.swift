import SwiftUI

struct MetricCard: View {
  let metric: MetricDefinition
  let project: Project?

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
      }
    }
  }
}
