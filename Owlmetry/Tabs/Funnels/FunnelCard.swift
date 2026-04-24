import SwiftUI

struct FunnelCard: View {
  let funnel: FunnelDefinition
  let project: Project?

  var body: some View {
    CardShell(accent: ProjectColor(project: project).base) {
      VStack(alignment: .leading, spacing: 6) {
        Text(funnel.name)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
          .multilineTextAlignment(.leading)
        HStack(spacing: 6) {
          Text(funnel.slug)
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Text("·")
            .foregroundStyle(.secondary)
          Text("\(funnel.steps.count) step\(funnel.steps.count == 1 ? "" : "s")")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        if let description = funnel.description, !description.isEmpty {
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
