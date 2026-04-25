import Foundation
import UIKit
import UserNotifications
import Owlmetry

enum PushAuthorization {
  /// Request provisional notification authorization (no scary prompt — banners
  /// land in Notification Center quietly until the user promotes them) and
  /// kick off APNs registration. Safe to call multiple times: UN handles the
  /// idempotency. Posts a metric on each outcome so we can spot rejection
  /// rates in the dashboard.
  static func requestAndRegister() async {
    let center = UNUserNotificationCenter.current()
    do {
      let granted = try await center.requestAuthorization(options: [
        .alert, .badge, .sound, .provisional,
      ])
      Owl.info("push.authorization", attributes: ["granted": granted ? "true" : "false"])
    } catch {
      Owl.error("push.authorization.failed", attributes: ["error": "\(error)"])
    }
    await MainActor.run {
      UIApplication.shared.registerForRemoteNotifications()
    }
  }
}
