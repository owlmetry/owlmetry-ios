import Owlmetry
import SwiftUI

struct SettingsSheet: View {
  @EnvironmentObject private var auth: AuthViewModel
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var showFeedback = false

  var body: some View {
    NavigationStack {
      Form {
        Section("Account") {
          LabeledContent("Name", value: auth.currentUser?.name ?? "—")
          LabeledContent("Email", value: auth.currentUser?.email ?? "—")
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
            dismiss()
          } label: {
            HStack {
              Spacer()
              Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
              Spacer()
            }
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
            .fontWeight(.semibold)
        }
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
      .owlScreen("Settings")
    }
  }
}
