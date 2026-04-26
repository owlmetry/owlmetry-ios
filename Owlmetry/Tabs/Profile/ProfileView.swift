import Owlmetry
import SwiftUI

struct ProfileView: View {
  @EnvironmentObject private var auth: AuthViewModel
  @EnvironmentObject private var appState: AppState
  @StateObject private var notifications = NotificationsListViewModel()
  @ObservedObject private var badgeStore = InboxBadgeStore.shared
  @State private var showFeedback = false

  var body: some View {
    Form {
      Section("Account") {
        LabeledContent("Name", value: auth.currentUser?.name ?? "—")
        LabeledContent("Email", value: auth.currentUser?.email ?? "—")
      }

      Section("Notifications") {
        NavigationLink(destination: NotificationsListView()) {
          HStack {
            Label("Inbox", systemImage: "bell")
            Spacer()
            if badgeStore.unreadCount > 0 {
              Text("\(badgeStore.unreadCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red, in: Capsule())
            }
          }
        }
        NavigationLink(destination: NotificationPreferencesView()) {
          Label("Preferences", systemImage: "slider.horizontal.3")
        }
      }

      Section("Team") {
        LabeledContent("Team", value: appState.currentTeam?.name ?? "—")
        LabeledContent("Role", value: (appState.currentTeam?.role ?? "—").capitalized)
        LabeledContent("Server", value: APIConfig.baseURL)
          .textSelection(.enabled)
      }

      Section("Data mode") {
        Picker("Mode", selection: Binding(
          get: { appState.dataMode },
          set: { appState.setDataMode($0) }
        )) {
          ForEach(DataMode.allCases) { mode in
            Text("\(mode.emoji) \(mode.displayName)").tag(mode)
          }
        }
        .pickerStyle(.inline)
        .labelsHidden()
      }

      Section("Feedback") {
        Button {
          showFeedback = true
        } label: {
          Label("Send feedback", systemImage: "bubble.left.and.bubble.right")
        }
      }

      Section {
        Button(role: .destructive) {
          auth.logout()
          appState.reset()
        } label: {
          HStack {
            Spacer()
            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
            Spacer()
          }
        }
      }
    }
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await notifications.refreshUnread()
    }
    .onAppear {
      // Re-runs after popping back from the inbox so the row count reflects
      // a mark-all-read immediately.
      Task { await notifications.refreshUnread() }
    }
    .autoRefresh(id: "profile-unread", every: 30) {
      await notifications.refreshUnread()
    }
    .sheet(isPresented: $showFeedback) {
      NavigationStack {
        OwlFeedbackView(
          name: auth.currentUser?.name,
          email: auth.currentUser?.email,
          onSubmitted: { _ in showFeedback = false },
          onCancel: { showFeedback = false }
        )
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
    .owlScreen("Profile")
  }
}
