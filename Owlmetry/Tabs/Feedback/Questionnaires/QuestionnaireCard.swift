import SwiftUI

struct QuestionnaireCard: View {
  let questionnaire: Questionnaire
  let project: Project?

  var body: some View {
    NavigableCard(accent: ProjectColor(project: project).base) {
      HStack(spacing: 8) {
        Text(questionnaire.name)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
        Spacer(minLength: 0)
        if !questionnaire.isActive {
          Text("Paused")
            .badgeStyle(tone: .secondary, size: .xs)
        }
      }
      Text(questionnaire.slug)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .lineLimit(1)
      HStack(spacing: 10) {
        Label("\(questionnaire.responseCount ?? 0) responses", systemImage: "list.clipboard")
        if let completed = questionnaire.submittedCount,
           let total = questionnaire.responseCount,
           total > 0 {
          Text("· \(completed) completed")
            .foregroundStyle(.tertiary)
        }
        Spacer()
        if questionnaire.lastResponseAt != nil {
          Label(RelativeDate.shortString(from: questionnaire.lastResponseAt), systemImage: "clock")
        }
      }
      .font(.caption2)
      .foregroundStyle(.secondary)
    }
  }
}
