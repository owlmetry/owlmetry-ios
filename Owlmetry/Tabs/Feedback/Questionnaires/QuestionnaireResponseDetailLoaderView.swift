import Combine
import Foundation
import Owlmetry
import SwiftUI

@MainActor
final class QuestionnaireResponseDetailViewModel: ObservableObject {
  @Published private(set) var detail: QuestionnaireResponseDetail?
  @Published private(set) var fallbackSchema: QuestionnaireSchema?
  @Published var errorMessage: String?

  func load(projectId: String, questionnaireId: String, responseId: String, dataMode: DataMode) async {
    do {
      async let detailTask = QuestionnairesService.responseDetail(
        projectId: projectId,
        questionnaireId: questionnaireId,
        responseId: responseId
      )
      async let schemaTask = QuestionnairesService.detail(
        projectId: projectId,
        questionnaireId: questionnaireId,
        dataMode: dataMode
      )
      let (loadedDetail, loadedQuestionnaire) = try await (detailTask, schemaTask)
      detail = loadedDetail
      fallbackSchema = loadedQuestionnaire.schema
    } catch let error as APIError {
      errorMessage = error.errorDescription
      Owl.error(
        "questionnaire.response.detail.load.failed",
        attributes: ["error": "\(error)", "response_id": responseId]
      )
    } catch {
      if error.isCancellation { return }
      errorMessage = error.localizedDescription
      Owl.error(
        "questionnaire.response.detail.load.failed",
        attributes: ["error": "\(error)", "response_id": responseId]
      )
    }
  }
}

struct QuestionnaireResponseDetailLoaderView: View {
  let projectId: String
  let questionnaireId: String
  let responseId: String

  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = QuestionnaireResponseDetailViewModel()

  var body: some View {
    Group {
      if let detail = viewModel.detail, let schema = effectiveSchema {
        QuestionnaireResponseDetailView(detail: detail, schema: schema)
      } else if let message = viewModel.errorMessage {
        ErrorState(message: message) { Task { await load() } }
      } else {
        LoadingState()
      }
    }
    .navigationTitle("Response")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .task(id: responseId) { await load() }
  }

  private var effectiveSchema: QuestionnaireSchema? {
    viewModel.detail?.response.schemaSnapshot ?? viewModel.fallbackSchema
  }

  private func load() async {
    await viewModel.load(
      projectId: projectId,
      questionnaireId: questionnaireId,
      responseId: responseId,
      dataMode: appState.dataMode
    )
  }
}
