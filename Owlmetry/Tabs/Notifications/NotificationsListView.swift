import Owlmetry
import SwiftUI

struct NotificationsListView: View {
  @StateObject private var viewModel = NotificationsListViewModel()

  var body: some View {
    content
      .navigationTitle("Notifications")
      .navigationBarTitleDisplayMode(.large)
      .task {
        await viewModel.reload()
      }
      .refreshable {
        await viewModel.reload()
      }
      .autoRefresh(id: "notifications-inbox", every: 30) {
        await viewModel.reload()
      }
      .onDisappear {
        Task { await viewModel.markAllReadIfNeeded() }
      }
      .owlScreen("NotificationsList")
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
    case .empty:
      EmptyState(
        systemImage: "bell.slash",
        title: "No notifications",
        subtitle: "New issues, feedback, and job alerts will appear here."
      )
    case .error(let message):
      EmptyState(
        systemImage: "exclamationmark.triangle",
        title: "Something went wrong",
        subtitle: message
      )
    case .loaded:
      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(viewModel.notifications) { notification in
            Button {
              Task { @MainActor in
                if notification.isUnread {
                  await viewModel.markRead(notification.id)
                }
                if let link = notification.link {
                  DeepLinkRouter.shared.handle(link)
                }
              }
            } label: {
              NotificationCard(notification: notification)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
          }
        }
        .padding(.vertical, 8)
      }
    }
  }
}
