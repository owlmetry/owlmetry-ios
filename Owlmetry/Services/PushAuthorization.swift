import Foundation
import UIKit
import UserNotifications
import Owlmetry

enum PushAuthorization {
  static func requestAndRegister() async {
    let center = UNUserNotificationCenter.current()
    do {
      let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
      Owl.info("push.authorization", attributes: ["granted": granted ? "true" : "false"])
      guard granted else { return }
    } catch {
      Owl.error("push.authorization.failed", attributes: ["error": "\(error)"])
      return
    }
    await MainActor.run {
      UIApplication.shared.registerForRemoteNotifications()
    }
  }
}
