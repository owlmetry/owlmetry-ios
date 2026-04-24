import SwiftUI

struct FilterSheet<Content: View>: View {
  let title: String
  let onClear: () -> Void
  let onApply: () -> Void
  @ViewBuilder var content: () -> Content

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form { content() }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Clear") {
              onClear()
            }
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button("Apply") {
              onApply()
              dismiss()
            }
            .fontWeight(.semibold)
          }
        }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}
