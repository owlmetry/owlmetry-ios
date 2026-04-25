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

    // Cold-start tap: defer until a scene is attached to consume the link.
    if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
       let link = userInfo["link"] as? String {
      Task { @MainActor in DeepLinkRouter.shared.handle(link) }
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

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Surface foreground notifications as banners; iOS suppresses them by default.
    completionHandler([.banner, .sound, .badge, .list])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let link = userInfo["link"] as? String {
      Task { @MainActor in DeepLinkRouter.shared.handle(link) }
    }
    completionHandler()
  }
}
