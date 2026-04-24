import SwiftUI

class Haptics {
  static func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle, withDelay: Double = 0) {
    let i = UIImpactFeedbackGenerator(style: feedbackStyle)
    i.prepare()

    DispatchQueue.main.asyncAfter(deadline: .now() + withDelay) {
      i.impactOccurred()
    }
  }

  static func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
    UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
  }
}
