import SwiftUI

struct QuestionAnalyticsView: View {
  let analytics: QuestionnaireQuestionAnalytics
  let schemaQuestion: QuestionnaireQuestion?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
      switch analytics {
      case .text(_, let total, let recent):
        textBody(total: total, recent: recent)
      case .singleChoice(_, let total, let choices):
        choiceBody(total: total, choices: choices, isMulti: false)
      case .multiChoice(_, let total, let choices):
        choiceBody(total: total, choices: choices, isMulti: true)
      case .rating(_, let total, let average, let buckets):
        ratingBody(total: total, average: average, buckets: buckets)
      case .nps(_, let total, let score, let detractors, let passives, let promoters, let buckets):
        npsBody(total: total, score: score, detractors: detractors, passives: passives, promoters: promoters, buckets: buckets)
      case .unknown:
        Text("Unsupported question type")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var title: String {
    schemaQuestion?.title ?? analytics.id
  }

  // MARK: - Text

  @ViewBuilder
  private func textBody(total: Int, recent: [QuestionnaireTextRecentAnswer]) -> some View {
    Text("\(total) answer\(total == 1 ? "" : "s")")
      .font(.caption2)
      .foregroundStyle(.tertiary)
    if recent.isEmpty {
      Text("No text answers yet.")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else {
      VStack(alignment: .leading, spacing: 6) {
        ForEach(recent.prefix(5)) { answer in
          HStack(alignment: .top, spacing: 6) {
            Text("·").foregroundStyle(.tertiary)
            Text(answer.answer)
              .font(.callout)
              .foregroundStyle(.primary)
              .lineLimit(3)
          }
        }
      }
    }
  }

  // MARK: - Choice

  @ViewBuilder
  private func choiceBody(total: Int, choices: [QuestionnaireChoiceCount], isMulti: Bool) -> some View {
    Text(isMulti
         ? "\(total) responses (multi-choice; sum exceeds total)"
         : "\(total) answer\(total == 1 ? "" : "s")")
      .font(.caption2)
      .foregroundStyle(.tertiary)
    let max = Swift.max(1, choices.map(\.count).max() ?? 1)
    VStack(alignment: .leading, spacing: 8) {
      ForEach(choices) { choice in
        let pct = total > 0 ? Int((Double(choice.count) / Double(total)) * 100) : 0
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(choice.label)
              .font(.caption)
              .foregroundStyle(.primary)
              .lineLimit(1)
            Spacer()
            Text("\(choice.count) (\(pct)%)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
          BarTrack(value: Double(choice.count) / Double(max), tint: .accentColor)
        }
      }
    }
  }

  // MARK: - Rating

  @ViewBuilder
  private func ratingBody(total: Int, average: Double?, buckets: [QuestionnaireRatingBucket]) -> some View {
    HStack(spacing: 8) {
      Text("\(total) answer\(total == 1 ? "" : "s")")
        .font(.caption2)
        .foregroundStyle(.tertiary)
      Spacer()
      if let average {
        Text(String(format: "avg %.1f", average))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
    }
    let max = Swift.max(1, buckets.map(\.count).max() ?? 1)
    VStack(alignment: .leading, spacing: 8) {
      ForEach(buckets) { bucket in
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            StarRow(rating: bucket.value, size: .sm)
            Spacer()
            Text("\(bucket.count)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
          BarTrack(value: Double(bucket.count) / Double(max), tint: .orange)
        }
      }
    }
  }

  // MARK: - NPS

  @ViewBuilder
  private func npsBody(total: Int, score: Double?, detractors: Int, passives: Int, promoters: Int, buckets: [QuestionnaireRatingBucket]) -> some View {
    HStack(spacing: 8) {
      Text("\(total) answer\(total == 1 ? "" : "s")")
        .font(.caption2)
        .foregroundStyle(.tertiary)
      Spacer()
      if let score {
        Text(String(format: "score %.0f", score))
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.primary)
          .monospacedDigit()
      }
    }
    HStack(spacing: 8) {
      Text("D: \(detractors)").font(.caption2).foregroundStyle(.red)
      Text("P: \(passives)").font(.caption2).foregroundStyle(.orange)
      Text("Pr: \(promoters)").font(.caption2).foregroundStyle(.green)
      Spacer()
    }
    let bucketsByValue = Dictionary(uniqueKeysWithValues: buckets.map { ($0.value, $0.count) })
    let max = Swift.max(1, buckets.map(\.count).max() ?? 1)
    HStack(alignment: .bottom, spacing: 3) {
      ForEach(0...10, id: \.self) { value in
        let count = bucketsByValue[value] ?? 0
        VStack(spacing: 4) {
          ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
              .fill(Color.secondary.opacity(0.12))
              .frame(height: 64)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
              .fill(npsColor(for: value))
              .frame(height: 64 * CGFloat(Double(count) / Double(max)))
          }
          Text("\(value)")
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value): \(count) responses")
      }
    }
  }

  private func npsColor(for value: Int) -> Color {
    if value <= 6 { return .red }
    if value <= 8 { return .orange }
    return .green
  }
}

private struct BarTrack: View {
  let value: Double
  let tint: Color

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule(style: .continuous)
          .fill(Color.secondary.opacity(0.12))
        Capsule(style: .continuous)
          .fill(tint)
          .frame(width: geo.size.width * max(0, min(1, value)))
      }
    }
    .frame(height: 6)
  }
}
