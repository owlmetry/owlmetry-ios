import Owlmetry
import SwiftUI

struct ReviewDetailView: View {
  let review: Review

  @EnvironmentObject private var appState: AppState

  private var project: Project? { appState.projectsById[review.projectId] }
  private var app: AppModel? { appState.apps.first(where: { $0.id == review.appId }) }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        if let title = review.title, !title.isEmpty {
          Text(title)
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 16)
        }
        bodyBox
        InfoGrid(items: infoItems).padding(.horizontal, 16)
        if let response = review.developerResponse, !response.isEmpty {
          developerResponseSection(response)
        }
      }
      .padding(.vertical, 16)
    }
    .navigationTitle("Review")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .owlScreen("ReviewDetail")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        ProjectDot(project: project, size: 10)
        Text(project?.name ?? "—")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        Text(review.store.shortName)
          .badgeStyle(tone: .secondary, size: .sm)
        Spacer()
      }
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        StarRow(rating: review.rating, size: .lg)
        Spacer()
        Text(RelativeDate.string(from: review.createdAtInStore))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 16)
  }

  private var bodyBox: some View {
    Text(review.body)
      .font(.body)
      .foregroundStyle(.primary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
      .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
      .padding(.horizontal, 16)
      .textSelection(.enabled)
  }

  private var infoItems: [InfoGrid.Item] {
    var items: [InfoGrid.Item] = [
      .init(label: "App", value: app?.name ?? review.appName),
      .init(label: "Store", value: review.store.shortName)
    ]
    items.append(.init(
      label: "Country",
      value: review.countryCode.map { "\(CountryFlag.emoji(for: $0)) \($0)" } ?? "—"
    ))
    items.append(.init(label: "Version", value: review.appVersion ?? "—", monospaced: true))
    if let reviewer = review.reviewerName, !reviewer.isEmpty {
      items.append(.init(label: "Reviewer", value: reviewer))
    }
    if let language = review.languageCode, !language.isEmpty {
      items.append(.init(label: "Language", value: language))
    }
    items.append(.init(label: "Posted", value: RelativeDate.string(from: review.createdAtInStore)))
    items.append(.init(label: "Ingested", value: RelativeDate.string(from: review.ingestedAt)))
    return items
  }

  private func developerResponseSection(_ response: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: "bubble.left.fill")
        Text("Developer response")
        Spacer()
        if let at = review.developerResponseAt {
          Text(RelativeDate.shortString(from: at))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.green)
      Text(response)
        .font(.callout)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.green.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.green.opacity(0.25), lineWidth: 1))
        .textSelection(.enabled)
    }
    .padding(.horizontal, 16)
  }
}
