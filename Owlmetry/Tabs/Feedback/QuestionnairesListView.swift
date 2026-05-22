import Owlmetry
import SwiftUI

struct QuestionnairesListNavRoute: Hashable {}

struct QuestionnairesListView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Image(systemName: "list.clipboard")
          .font(.system(size: 44, weight: .regular))
          .foregroundStyle(.secondary)
          .padding(.top, 64)
        Text("Questionnaires")
          .font(.title3.weight(.semibold))
        Text("Detailed questionnaire response browsing is coming soon. For now, use the web dashboard or the Owlmetry CLI.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }
      .frame(maxWidth: .infinity)
    }
    .navigationTitle("Questionnaires")
    .navigationBarTitleDisplayMode(.inline)
    .owlScreen("QuestionnairesList")
  }
}
