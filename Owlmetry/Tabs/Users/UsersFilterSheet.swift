import Owlmetry
import SwiftUI

struct UsersFilterSheet: View {
  @State var filter: UsersFilter
  let apps: [AppModel]
  let onApply: (UsersFilter) -> Void
  let onClear: () -> Void

  var body: some View {
    FilterSheet(
      title: "Filter Users",
      onClear: {
        filter = UsersFilter()
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
      Section("Time range") {
        Picker("Seen", selection: $filter.timeRange) {
          ForEach(UsersTimeRange.allCases) { range in
            Text(range.displayName).tag(range)
          }
        }
      }
      Section("Type") {
        Picker("Type", selection: $filter.type) {
          ForEach(UserTypeFilter.allCases) { type in
            Text(type.displayName).tag(type)
          }
        }
      }
      Section("Billing") {
        ForEach(BillingStatus.allCases) { status in
          let isOn = Binding<Bool>(
            get: { filter.billing.contains(status) },
            set: { on in
              if on { filter.billing.insert(status) } else { filter.billing.remove(status) }
            }
          )
          Toggle(isOn: isOn) {
            HStack {
              Text(status.emoji)
              Text(status.displayName)
            }
          }
        }
      }
    }
    .owlScreen("UsersFilter")
  }
}
