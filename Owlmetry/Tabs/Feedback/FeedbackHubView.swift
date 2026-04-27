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
            Text("Public reviews from the App Store, refreshed daily.")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .buttonStyle(.plain)

        NavigationLink(value: RatingsListNavRoute()) {
          NavigableCard(accent: .yellow) {
            Label("Ratings", systemImage: "star.leadinghalf.filled")
              .font(.headline)
              .foregroundStyle(.primary)
            Text("Average ratings across your apps and countries.")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
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
}
