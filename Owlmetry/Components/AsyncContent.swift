import SwiftUI

struct AsyncContent<Value, Content: View>: View {
  let state: Loadable<Value>
  var retry: (() -> Void)? = nil
  var emptyTitle: String = "Nothing to show"
  var emptySubtitle: String? = nil
  var emptySystemImage: String = "tray"
  @ViewBuilder var content: (Value) -> Content

  var body: some View {
    switch state {
    case .idle:
      Color.clear
    case .loading:
      LoadingState()
    case .loaded(let value):
      content(value)
    case .empty:
      EmptyState(systemImage: emptySystemImage, title: emptyTitle, subtitle: emptySubtitle)
    case .error(let message):
      ErrorState(message: message, retry: retry)
    }
  }
}
