import Owlmetry
import SwiftUI

struct ReviewFilterSheet: View {
  @State var filter: ReviewFilter
  let apps: [AppModel]
  let onApply: (ReviewFilter) -> Void
  let onClear: () -> Void

  var body: some View {
    FilterSheet(
      title: "Filter Reviews",
      onClear: {
        filter = ReviewFilter()
        onClear()
      },
      onApply: { onApply(filter) }
    ) {
      Section("Search") {
        TextField("Title, body, or reviewer", text: $filter.search)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
      }
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
      Section("Store") {
        Picker("Store", selection: Binding(
          get: { filter.store?.rawValue ?? "" },
          set: { filter.store = $0.isEmpty ? nil : ReviewStore(rawValue: $0) }
        )) {
          Text("All stores").tag("")
          ForEach(ReviewStore.allCases) { store in
            Text(store.displayName).tag(store.rawValue)
          }
        }
      }
      Section("Rating") {
        Picker("Rating", selection: Binding(
          get: { filter.rating ?? 0 },
          set: { filter.rating = $0 == 0 ? nil : $0 }
        )) {
          Text("Any").tag(0)
          ForEach((1...5).reversed(), id: \.self) { stars in
            Text(String(repeating: "★", count: stars)).tag(stars)
          }
        }
      }
    }
    .owlScreen("ReviewFilter")
  }
}
