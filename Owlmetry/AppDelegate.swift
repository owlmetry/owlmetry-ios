import Foundation
import UIKit
import UserNotifications
import Owlmetry

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    Task { await PushAuthorization.requestAndRegister() }

    // Cold-start notification tap: deliver the deep link as soon as we have
    // an attached scene to consume it.
    if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
       let link = userInfo["link"] as? String {
      Task { @MainActor in
        DeepLinkRouter.shared.handle(link)
      }
    }
    return true
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = DevicesService.hexToken(from: deviceToken)
    Task {
      do {
        try await DevicesService.register(token: token)
        Owl.info("push.device.registered")
      } catch {
        Owl.error("push.device.register_failed", attributes: ["error": "\(error)"])
      }
    }
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    Owl.error("push.register_failed", attributes: ["error": "\(error)"])
  }

  // Foreground delivery — still show the banner so the user notices.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge, .list])
  }

  // Tap handler — extract the link payload and route through DeepLinkRouter.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let link = userInfo["link"] as? String {
      Task { @MainActor in
        DeepLinkRouter.shared.handle(link)
      }
    }
    completionHandler()
  }
}
