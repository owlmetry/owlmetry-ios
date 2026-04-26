import Combine
import Owlmetry
import SwiftUI

/// Shape of `users.preferences.notifications` we care about. Other keys
/// under `preferences` (ui.columns) are deliberately not modeled — we only
/// touch this slice, and Swift's Codable ignores unknown fields when we
/// fetch the partial response.
private struct NotifPrefsEnvelope: Decodable {
  let user: UserSlice
  struct UserSlice: Decodable {
    let preferences: PrefsSlice?
  }
  struct PrefsSlice: Decodable {
    let notifications: NotifSlice?
  }
  struct NotifSlice: Decodable {
    let types: [String: [String: Bool]]?
  }
}

private struct PatchPrefsBody: Encodable {
  let preferences: PrefsPatch
  struct PrefsPatch: Encodable {
    let notifications: NotifPatch
  }
  struct NotifPatch: Encodable {
    let types: [String: [String: Bool]]
  }
}

/// Notification types and their channels — mirrors @owlmetry/shared's
/// NOTIFICATION_TYPE_META (packages/shared/src/preferences.ts). Kept local
/// because the iOS app doesn't pull from the npm package; the server
/// validates inputs anyway.
///
/// KEEP IN SYNC: when a new type is added to NOTIFICATION_TYPES /
/// NOTIFICATION_TYPE_META in shared, append the matching spec below — the
/// web page renders straight from the shared map so it auto-updates, but
/// iOS does not and will silently omit the type from this screen.
private struct NotificationTypeSpec {
  let type: String
  let label: String
  let description: String
  let channels: [(String, String)]   // (channel, label)
  let defaults: [String: Bool]
}

private let NOTIFICATION_TYPE_SPECS: [NotificationTypeSpec] = [
  .init(
    type: "issue.new",
    label: "New issues",
    description: "Push as soon as a new or regressed issue is detected by the hourly scan. Bypasses the per-project digest cadence.",
    channels: [("in_app", "In-app"), ("email", "Email"), ("ios_push", "iOS push")],
    defaults: ["in_app": true, "email": false, "ios_push": true]
  ),
  .init(
    type: "issue.digest",
    label: "Issue digests",
    description: "Periodic summary of new or regressed issues for your projects.",
    channels: [("in_app", "In-app"), ("email", "Email"), ("ios_push", "iOS push")],
    defaults: ["in_app": true, "email": true, "ios_push": true]
  ),
  .init(
    type: "feedback.new",
    label: "New feedback",
    description: "When a user submits feedback in one of your apps.",
    channels: [("in_app", "In-app"), ("email", "Email"), ("ios_push", "iOS push")],
    defaults: ["in_app": true, "email": true, "ios_push": true]
  ),
  .init(
    type: "job.completed",
    label: "Job completion",
    description: "When a manual job you triggered with --notify finishes.",
    channels: [("in_app", "In-app"), ("email", "Email"), ("ios_push", "iOS push")],
    defaults: ["in_app": true, "email": true, "ios_push": false]
  ),
]

@MainActor
private final class NotificationPreferencesViewModel: ObservableObject {
  @Published var state: Loadable<Void> = .idle
  @Published var overrides: [String: [String: Bool]] = [:]

  func load() async {
    state = .loading
    do {
      let res: NotifPrefsEnvelope = try await APIClient.shared.get("/v1/auth/me")
      overrides = res.user.preferences?.notifications?.types ?? [:]
      state = .loaded(())
    } catch let error as APIError {
      state = .error(error.errorDescription ?? "Failed to load preferences")
    } catch {
      if error.isCancellation { return }
      state = .error(error.localizedDescription)
    }
  }

  /// Returns the effective on/off for a (type, channel) — user override if
  /// present, otherwise the type's default.
  func isEnabled(type: String, channel: String, defaults: [String: Bool]) -> Bool {
    if let user = overrides[type]?[channel] { return user }
    return defaults[channel] ?? false
  }

  func setEnabled(type: String, channel: String, value: Bool) async {
    var typeOverrides = overrides[type] ?? [:]
    typeOverrides[channel] = value
    overrides[type] = typeOverrides

    let patch = PatchPrefsBody(
      preferences: .init(notifications: .init(types: [type: [channel: value]]))
    )
    do {
      let _: NotifPrefsEnvelope = try await APIClient.shared.patch(
        "/v1/auth/me",
        body: patch
      )
    } catch {
      Owl.error("notifications.prefs.patch_failed", attributes: ["error": "\(error)"])
      // Rollback on failure
      typeOverrides[channel] = !value
      overrides[type] = typeOverrides
    }
  }
}

struct NotificationPreferencesView: View {
  @StateObject private var viewModel = NotificationPreferencesViewModel()

  var body: some View {
    Form {
      Section {
        Text("Choose which channels deliver each notification type. Per-project alert frequency for issue digests is configured in each project's web settings.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      ForEach(NOTIFICATION_TYPE_SPECS, id: \.type) { spec in
        Section(spec.label) {
          Text(spec.description)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
          ForEach(spec.channels, id: \.0) { (channel, label) in
            Toggle(label, isOn: Binding(
              get: { viewModel.isEnabled(type: spec.type, channel: channel, defaults: spec.defaults) },
              set: { newValue in
                Task { await viewModel.setEnabled(type: spec.type, channel: channel, value: newValue) }
              }
            ))
          }
        }
      }
    }
    .navigationTitle("Notification preferences")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.load() }
    .owlScreen("NotificationPreferences")
  }
}
