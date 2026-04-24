import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var auth: AuthViewModel

  let user: User

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Spacer()

        Image(systemName: "bird.fill")
          .font(.system(size: 64))
          .foregroundStyle(.tint)

        Text("Home")
          .font(.largeTitle.bold())

        Text("Signed in as \(user.email)")
          .font(.body)
          .foregroundColor(.secondary)

        if !auth.teams.isEmpty {
          VStack(spacing: 4) {
            Text("Teams")
              .font(.caption.bold())
              .foregroundColor(.secondary)
            ForEach(auth.teams) { team in
              Text("\(team.name) · \(team.role)")
                .font(.callout)
            }
          }
          .padding(.top, 8)
        }

        Spacer()

        CtaButton(title: "Log out", type: .secondary) {
          await MainActor.run { auth.logout() }
        }
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 16)
    }
  }
}
