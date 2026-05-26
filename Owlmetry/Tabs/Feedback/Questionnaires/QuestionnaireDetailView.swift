import Owlmetry
import SwiftUI

struct QuestionnaireDetailView: View {
  let projectId: String
  let questionnaireId: String

  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = QuestionnaireDetailViewModel()

  var body: some View {
    content
      .navigationTitle(viewModel.questionnaire?.name ?? "Questionnaire")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(.hidden, for: .tabBar)
      .task(id: refreshKey) { await reload() }
      .refreshable { await reload() }
      .owlScreen("QuestionnaireDetail")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading where viewModel.questionnaire == nil:
      LoadingState()
    case .error(let message) where viewModel.questionnaire == nil:
      ErrorState(message: message) { Task { await reload() } }
    default:
      if let questionnaire = viewModel.questionnaire {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            header(for: questionnaire)
            stats(for: questionnaire)
            if let analytics = viewModel.analytics {
              analyticsCard(analytics: analytics, schema: questionnaire.schema)
            }
            responsesCard(for: questionnaire)
          }
          .padding(.vertical, 16)
        }
      }
    }
  }

  // MARK: - Sections

  private func header(for questionnaire: Questionnaire) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        if let project = appState.projectsById[questionnaire.projectId] {
          ProjectDot(project: project, size: 10)
          Text(project.name)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        Spacer()
        if questionnaire.isActive {
          Text("Active").badgeStyle(tone: .green, size: .sm)
        } else {
          Text("Paused").badgeStyle(tone: .secondary, size: .sm)
        }
      }
      Text(questionnaire.name)
        .font(.title3.weight(.semibold))
      Text(questionnaire.slug)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
      if let description = questionnaire.description, !description.isEmpty {
        Text(description)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 16)
  }

  private func stats(for questionnaire: Questionnaire) -> some View {
    let total = questionnaire.responseCount ?? 0
    let submitted = questionnaire.submittedCount ?? 0
    let inProgress = max(0, total - submitted)
    let breakdown = total > 0 ? "\(submitted) completed · \(inProgress) in progress" : nil
    let lastResponse = questionnaire.lastResponseAt.map { RelativeDate.string(from: $0) } ?? "—"
    return LazyVGrid(
      columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
      spacing: 10
    ) {
      SimpleStat(label: "Responses", value: "\(total)", sublabel: breakdown)
      SimpleStat(label: "Last", value: lastResponse, sublabel: nil)
      SimpleStat(label: "Questions", value: "\(questionnaire.schema.questions.count)", sublabel: nil)
    }
    .padding(.horizontal, 16)
  }

  private func analyticsCard(analytics: QuestionnaireAnalytics, schema: QuestionnaireSchema) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        Text("Analytics")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text("\(analytics.totalResponses) total · \(analytics.submittedCount) completed")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      VStack(alignment: .leading, spacing: 18) {
        ForEach(analytics.questions) { questionAnalytics in
          QuestionAnalyticsView(
            analytics: questionAnalytics,
            schemaQuestion: schema.questions.first(where: { $0.id == questionAnalytics.id })
          )
        }
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.cardBackground))
      .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
      .padding(.horizontal, 16)
    }
  }

  private func responsesCard(for questionnaire: Questionnaire) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Recent responses")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      if viewModel.responses.isEmpty {
        Text("No responses yet.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16)
      } else {
        VStack(spacing: 8) {
          ForEach(viewModel.responses) { response in
            NavigationLink(value: QuestionnaireResponseDetailNavRoute(
              projectId: projectId,
              questionnaireId: questionnaireId,
              responseId: response.id
            )) {
              QuestionnaireResponseRow(
                response: response,
                totalQuestions: questionnaire.schema.questions.count
              )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 16)
      }
    }
  }

  // MARK: - Helpers

  private var refreshKey: String {
    "\(projectId)|\(questionnaireId)|\(appState.dataMode.rawValue)"
  }

  private func reload() async {
    await viewModel.load(
      projectId: projectId,
      questionnaireId: questionnaireId,
      dataMode: appState.dataMode
    )
  }
}

private struct SimpleStat: View {
  let label: String
  let value: String
  let sublabel: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label.uppercased())
        .font(.system(size: 9, weight: .semibold))
        .tracking(0.6)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      if let sublabel {
        Text(sublabel)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(2)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
  }
}

private struct QuestionnaireResponseRow: View {
  let response: QuestionnaireResponse
  let totalQuestions: Int

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      VStack(alignment: .leading, spacing: 3) {
        Text(submitterLabel)
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(1)
        HStack(spacing: 6) {
          if let appVersion = response.appVersion {
            Text(appVersion).font(.caption2.monospaced())
          }
          if let environment = response.environment {
            Text(environment).font(.caption2)
          }
          if let country = response.countryCode {
            Text("\(CountryFlag.emoji(for: country))").font(.caption2)
          }
        }
        .foregroundStyle(.secondary)
      }
      Spacer(minLength: 8)
      VStack(alignment: .trailing, spacing: 4) {
        ResponseStateBadge(
          isComplete: response.isComplete,
          answered: response.answers.count,
          total: totalQuestions
        )
        Text(RelativeDate.shortString(from: response.createdAt))
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.cardBackground))
    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
  }

  private var submitterLabel: String {
    if let userId = response.userId, !userId.isEmpty {
      return userId
    }
    return "Anonymous"
  }
}

struct ResponseStateBadge: View {
  let isComplete: Bool
  let answered: Int
  let total: Int

  var body: some View {
    let label = "\(isComplete ? "Submitted" : "Draft") · \(answered)/\(total)"
    Text(label)
      .badgeStyle(tone: isComplete ? .green : .orange, size: .xs)
  }
}
