import Combine
import Foundation
import Owlmetry

@MainActor
final class QuestionnaireDetailViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published private(set) var questionnaire: Questionnaire?
  @Published private(set) var analytics: QuestionnaireAnalytics?
  @Published private(set) var responses: [QuestionnaireResponse] = []

  func load(projectId: String, questionnaireId: String, dataMode: DataMode) async {
    if questionnaire == nil { state = .loading }
    do {
      async let detailTask = QuestionnairesService.detail(
        projectId: projectId,
        questionnaireId: questionnaireId,
        dataMode: dataMode
      )
      async let analyticsTask = QuestionnairesService.analytics(
        projectId: projectId,
        questionnaireId: questionnaireId,
        dataMode: dataMode
      )
      async let responsesTask = QuestionnairesService.responses(
        projectId: projectId,
        questionnaireId: questionnaireId,
        dataMode: dataMode,
        limit: 50,
        submittedOnly: false
      )
      let (detail, analyticsResp, responsesDto) = try await (detailTask, analyticsTask, responsesTask)
      questionnaire = detail
      analytics = analyticsResp
      responses = responsesDto.responses
      state = .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load questionnaire")
      Owl.error("questionnaire.detail.load.failed", attributes: ["error": "\(error)", "questionnaire_id": questionnaireId])
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
      Owl.error("questionnaire.detail.load.failed", attributes: ["error": "\(error)", "questionnaire_id": questionnaireId])
    }
  }
}
