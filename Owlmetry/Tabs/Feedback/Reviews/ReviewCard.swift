import SwiftUI

struct ReviewCard: View {
  let review: Review
  let app: AppModel?
  let project: Project?

  var body: some View {
    NavigableCard(accent: ProjectColor(project: project).base) {
      HStack(alignment: .firstTextBaseline) {
        StarRow(rating: review.rating, size: .sm)
        Spacer()
        Text(RelativeDate.shortString(from: review.createdAtInStore))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      if let title = review.title, !title.isEmpty {
        Text(title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)
      }

      Text(review.body)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(3)
        .multilineTextAlignment(.leading)

      HStack(spacing: 6) {
        if app != nil {
          AppBadge(app: app, project: project, size: .xs)
        }
        Text(review.store.shortName)
          .badgeStyle(tone: .secondary, size: .xs)
        if let version = review.appVersion, !version.isEmpty {
          VersionBadge(version: version, latestVersion: app?.latestAppVersion, size: .xs)
        }
        if review.developerResponse != nil {
          Label("Replied", systemImage: "bubble.left.fill")
            .badgeStyle(tone: .green, size: .xs)
        }
      }

      HStack(spacing: 10) {
        if let reviewer = review.reviewerName, !reviewer.isEmpty {
          Text(reviewer)
            .lineLimit(1)
            .truncationMode(.middle)
        }
        if let country = review.countryCode {
          CountryCell(code: country, showCode: false)
        }
        Spacer()
      }
      .font(.caption2)
      .foregroundStyle(.secondary)
    }
  }
}
