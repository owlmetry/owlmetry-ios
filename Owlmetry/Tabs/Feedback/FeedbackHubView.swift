import Owlmetry
import SwiftUI

struct FeedbackListNavRoute: Hashable {}
struct ReviewsListNavRoute: Hashable {}

struct FeedbackHubView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        NavigationLink(value: FeedbackListNavRoute()) {
          NavigableCard(accent: .accentColor) {
            Label("In-App Feedback", systemImage: "bubble.left")
              .font(.headline)
              .foregroundStyle(.primary)
            Text("Submissions from the in-app feedback view, with status tracking.")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .buttonStyle(.plain)

        NavigationLink(value: ReviewsListNavRoute()) {
          NavigableCard(accent: .orange) {
            Label("App Store Reviews", systemImage: "star.bubble")
              .font(.headline)
              .foregroundStyle(.primary)
            HStack(spacing: 8) {
              Text("Public reviews from the App Store, refreshed daily.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
              Spacer(minLength: 0)
            }
            if let summary = teamRatingSummary {
              RatingBadge(
                rating: summary.average,
                count: summary.total,
                size: .sm
              )
            }
          }
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .navigationTitle("Feedback")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
    }
    .owlScreen("FeedbackHub")
  }

  private var teamRatingSummary: (average: Double, total: Int)? {
    let scopedApps = appState.apps.filter {
      appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId
    }
    var weightedSum: Double = 0
    var total: Int = 0
    for app in scopedApps {
      guard let rating = app.latestRating, let count = app.latestRatingCount, count > 0 else { continue }
      weightedSum += rating * Double(count)
      total += count
    }
    guard total > 0 else { return nil }
    return (weightedSum / Double(total), total)
  }
}
