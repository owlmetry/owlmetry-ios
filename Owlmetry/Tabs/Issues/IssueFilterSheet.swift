import Owlmetry
import SwiftUI

struct IssueFilterSheet: View {
  @State var filter: IssueFilter
  let apps: [AppModel]
  let onApply: (IssueFilter) -> Void
  let onClear: () -> Void

  var body: some View {
    FilterSheet(
      title: "Filter Issues",
      onClear: {
        filter = IssueFilter()
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
        Toggle("Include dev mode issues", isOn: $filter.includeDev)
      }
    }
    .owlScreen("IssuesFilter")
  }
}
