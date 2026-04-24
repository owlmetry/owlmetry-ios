import Owlmetry
import SwiftUI

struct FeedbackFilterSheet: View {
  @State var filter: FeedbackFilter
  let apps: [AppModel]
  let onApply: (FeedbackFilter) -> Void
  let onClear: () -> Void

  var body: some View {
    FilterSheet(
      title: "Filter Feedback",
      onClear: {
        filter = FeedbackFilter()
        onClear()
      },
      onApply: { onApply(filter) }
    ) {
      Section("App") {
        Picker("App", selection: Binding(
          get: { filter.appId ?? "" },
          set: { filter.appId = $0.isEmpty ? nil : $0 }
        )) {
          Text("All apps").tag("")
          ForEach(apps) { app in
            Text("\(app.platform.emoji) \(app.name)").tag(app.id)
          }
        }
      }
      Section("Data") {
        Toggle("Include dev mode feedback", isOn: $filter.includeDev)
      }
    }
    .owlScreen("FeedbackFilter")
  }
}
