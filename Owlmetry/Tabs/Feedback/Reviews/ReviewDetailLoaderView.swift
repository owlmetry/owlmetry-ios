import Owlmetry
import SwiftUI

struct ReviewDetailLoaderView: View {
  let projectId: String
  let reviewId: String

  @State private var review: Review?
  @State private var errorMessage: String?
  @State private var failed = false

  var body: some View {
    Group {
      if let review {
        ReviewDetailView(review: review)
      } else if failed {
        VStack(spacing: 8) {
          Text("Couldn't load review")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          if let msg = errorMessage {
            Text(msg).font(.caption).foregroundStyle(.tertiary)
          }
          Button("Retry") { Task { await load() } }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .task(id: reviewId) { await load() }
    .navigationTitle("Review")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func load() async {
    failed = false
    errorMessage = nil
    do {
      review = try await ReviewsService.detail(projectId: projectId, reviewId: reviewId)
    } catch let error as APIError {
      errorMessage = error.errorDescription
      failed = true
      Owl.error("review.load.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      errorMessage = error.localizedDescription
      failed = true
      Owl.error("review.load.failed", attributes: ["error": "\(error)"])
    }
  }
}
