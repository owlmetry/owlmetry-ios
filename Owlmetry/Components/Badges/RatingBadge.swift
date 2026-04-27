import SwiftUI

struct RatingBadge: View {
  let rating: Double?
  let count: Int?
  var currentVersionRating: Double? = nil
  var currentVersionRatingCount: Int? = nil
  var size: BadgeSize = .sm

  var body: some View {
    if let rating, rating > 0 {
      filled(rating: rating)
    } else {
      empty
    }
  }

  private var empty: some View {
    HStack(spacing: 4) {
      Image(systemName: "star")
      Text("No ratings yet")
    }
    .font(size.font)
    .foregroundStyle(.secondary)
  }

  private func filled(rating: Double) -> some View {
    let reviewers = count ?? 0
    return HStack(spacing: 4) {
      Image(systemName: "star.fill")
        .foregroundStyle(.orange)
      Text(String(format: "%.1f", rating))
        .foregroundStyle(.primary)
      Text("(\(Self.formatCount(reviewers)))")
        .foregroundStyle(.secondary)
    }
    .font(size.font.weight(.medium))
    .padding(.horizontal, size.horizontalPadding)
    .padding(.vertical, size.verticalPadding)
    .background(
      Capsule(style: .continuous)
        .fill(Color.orange.opacity(0.10))
    )
    .overlay(
      Capsule(style: .continuous)
        .stroke(Color.orange.opacity(0.30), lineWidth: 1)
    )
    .fixedSize()
    .accessibilityLabel(accessibilityText(rating: rating, count: reviewers))
  }

  private func accessibilityText(rating: Double, count: Int) -> String {
    var text = String(format: "%.1f stars, %d ratings", rating, count)
    if let current = currentVersionRating {
      text += String(format: ". Current version %.1f", current)
      if let currentCount = currentVersionRatingCount {
        text += " across \(currentCount) ratings"
      }
    }
    return text
  }

  static func formatCount(_ count: Int) -> String {
    if count < 1_000 { return String(count) }
    if count < 1_000_000 {
      let value = Double(count) / 1_000
      let formatted = count < 10_000 ? String(format: "%.1f", value) : String(format: "%.0f", value)
      return "\(stripTrailingZero(formatted))k"
    }
    let value = Double(count) / 1_000_000
    return "\(stripTrailingZero(String(format: "%.1f", value)))M"
  }

  private static func stripTrailingZero(_ s: String) -> String {
    s.hasSuffix(".0") ? String(s.dropLast(2)) : s
  }
}
