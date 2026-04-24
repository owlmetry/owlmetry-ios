import Owlmetry
import SwiftUI

struct ServerURLSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var auth: AuthViewModel
  @State private var urlText: String = APIConfig.baseURL
  @State private var validationError: String?

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("https://api.owlmetry.com", text: $urlText)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.URL)
        } header: {
          Text("API Server")
        } footer: {
          Text("Point the app at your self-hosted Owlmetry deployment. Changing the server signs you out.")
        }

        if let validationError {
          Section {
            Text(validationError)
              .font(.caption)
              .foregroundColor(.red)
          }
        }

        Section {
          Button("Reset to default") {
            urlText = APIConfig.defaultBaseURL
            validationError = nil
          }
          .disabled(urlText == APIConfig.defaultBaseURL)
        }
      }
      .navigationTitle("Custom server")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
        }
      }
      .owlScreen("ServerURL")
    }
  }

  private func save() {
    let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: trimmed),
          let scheme = url.scheme?.lowercased(),
          scheme == "http" || scheme == "https",
          url.host != nil else {
      validationError = "Enter a valid http(s) URL."
      return
    }

    let previous = APIConfig.baseURL
    APIConfig.baseURL = trimmed
    if APIConfig.baseURL != previous {
      Owl.info("server_url.changed", screenName: "ServerURL")
      auth.logout()
    }
    if urlText == APIConfig.defaultBaseURL && previous != APIConfig.defaultBaseURL {
      Owl.info("server_url.reset", screenName: "ServerURL")
    }
    Haptics.notify(.success)
    dismiss()
  }
}
