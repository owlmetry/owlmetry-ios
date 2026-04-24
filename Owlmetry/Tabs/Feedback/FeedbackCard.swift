import SwiftUI

struct FeedbackCard: View {
  let feedback: Feedback
  let app: AppModel?
  let project: Project?

  var body: some View {
    CardShell(accent: ProjectColor(project: project).base) {
      VStack(alignment: .leading, spacing: 8) {
        Text(feedback.message)
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(3)
          .multilineTextAlignment(.leading)
        HStack(spacing: 6) {
          if app != nil {
            AppBadge(app: app, project: project, size: .xs)
          }
          if feedback.isDev == true {
            DevModeBadge(size: .xs)
          }
          BillingBadge(properties: feedback.userProperties, size: .xs)
          AttributionBadge(properties: feedback.userProperties, size: .xs)
        }
        HStack(spacing: 10) {
          Text(submitterLabel)
            .lineLimit(1)
            .truncationMode(.middle)
          if let country = feedback.countryCode {
            CountryCell(code: country, showCode: false)
          }
          Spacer()
          Label(RelativeDate.shortString(from: feedback.createdAt), systemImage: "clock")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
    }
  }

  private var submitterLabel: String {
    feedback.submitterName
      ?? feedback.submitterEmail
      ?? (feedback.userId.map { String($0.prefix(8)) } ?? "anonymous")
  }
}
