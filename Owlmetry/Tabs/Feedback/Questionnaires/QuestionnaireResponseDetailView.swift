import Owlmetry
import SwiftUI

struct QuestionnaireResponseDetailView: View {
  let detail: QuestionnaireResponseDetail
  let schema: QuestionnaireSchema

  private var response: QuestionnaireResponse { detail.response }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        InfoGrid(items: infoItems).padding(.horizontal, 16)
        answersSection
        if !detail.comments.isEmpty { commentsSection }
      }
      .padding(.vertical, 16)
    }
    .owlScreen("QuestionnaireResponseDetail")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        ResponseStateBadge(
          isComplete: response.isComplete,
          answered: response.answers.count,
          total: schema.questions.count
        )
        if response.isDev == true {
          DevModeBadge(size: .sm)
        }
        Spacer()
      }
      Text(stateLine)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 16)
  }

  private var stateLine: String {
    if response.isComplete {
      let submitted = response.submittedAt ?? response.createdAt
      return "Submitted \(RelativeDate.string(from: submitted))"
    }
    return "In progress — last saved \(RelativeDate.string(from: response.updatedAt))"
  }

  private var infoItems: [InfoGrid.Item] {
    var items: [InfoGrid.Item] = []
    items.append(.init(label: "User", value: response.userId ?? "anonymous", monospaced: response.userId != nil))
    items.append(.init(label: "Created", value: RelativeDate.string(from: response.createdAt)))
    items.append(.init(label: "Version", value: response.appVersion ?? "—", monospaced: response.appVersion != nil))
    items.append(.init(label: "Environment", value: response.environment ?? "—"))
    if let country = response.countryCode {
      items.append(.init(label: "Country", value: "\(CountryFlag.emoji(for: country)) \(country)"))
    }
    if let device = response.deviceModel {
      items.append(.init(label: "Device", value: device))
    }
    if let os = response.osVersion {
      items.append(.init(label: "OS", value: os))
    }
    return items
  }

  private var answersSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Answers")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(alignment: .leading, spacing: 14) {
        ForEach(schema.questions) { question in
          AnswerRow(question: question, value: response.answers[question.id])
        }
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.cardBackground))
      .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
      .padding(.horizontal, 16)
    }
  }

  private var commentsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Comments")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      VStack(alignment: .leading, spacing: 10) {
        ForEach(detail.comments) { comment in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(comment.authorName).font(.caption.weight(.semibold))
              Spacer()
              Text(RelativeDate.shortString(from: comment.createdAt))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Text(comment.body).font(.callout)
          }
          .padding(12)
          .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.cardBackground))
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct AnswerRow: View {
  let question: QuestionnaireQuestion
  let value: QuestionnaireAnswerValue?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(question.title)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private var content: some View {
    if value == nil {
      Text("(no answer)")
        .font(.callout)
        .foregroundStyle(.tertiary)
        .italic()
    } else {
      switch question {
      case .text:
        Text(value?.asString ?? "")
          .font(.callout)
          .textSelection(.enabled)
      case .singleChoice(let payload):
        if let id = value?.asString {
          Text(payload.options.first(where: { $0.id == id })?.label ?? id)
            .font(.callout)
        } else {
          Text("—").foregroundStyle(.tertiary)
        }
      case .multiChoice(let payload):
        if let ids = value?.asStrings, !ids.isEmpty {
          let labels = ids.map { id in payload.options.first(where: { $0.id == id })?.label ?? id }
          Text(labels.joined(separator: ", "))
            .font(.callout)
        } else {
          Text("—").foregroundStyle(.tertiary)
        }
      case .rating(let payload):
        if let n = value?.asNumber {
          HStack(spacing: 8) {
            StarRow(rating: n, size: .lg)
            Text("\(n)/\(payload.scale)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
        } else {
          Text("—").foregroundStyle(.tertiary)
        }
      case .nps:
        if let n = value?.asNumber {
          Text("\(n)/10")
            .badgeStyle(tone: npsColor(for: n), size: .md)
        } else {
          Text("—").foregroundStyle(.tertiary)
        }
      case .unknown:
        Text(rawString(of: value))
          .font(.callout.monospaced())
          .foregroundStyle(.secondary)
      }
    }
  }

  private func npsColor(for value: Int) -> Color {
    if value <= 6 { return .red }
    if value <= 8 { return .orange }
    return .green
  }

  private func rawString(of value: QuestionnaireAnswerValue?) -> String {
    switch value {
    case .some(.string(let s)): return s
    case .some(.strings(let arr)): return arr.joined(separator: ", ")
    case .some(.number(let n)): return "\(n)"
    case .none: return ""
    }
  }
}
