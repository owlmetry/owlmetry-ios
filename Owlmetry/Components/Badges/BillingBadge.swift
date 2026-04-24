import SwiftUI

struct BillingBadge: View {
  let properties: [String: String]?
  var size: BadgeSize = .sm

  var body: some View {
    if let status = derivedStatus {
      HStack(spacing: 4) {
        Text(status.emoji)
        Text(label(for: status))
      }
      .badgeStyle(tone: Theme.Billing.color(for: status), size: size)
    } else {
      EmptyView()
    }
  }

  private var derivedStatus: BillingStatus? {
    guard let properties else { return nil }
    let isSubscriber = properties["rc_subscriber"]?.lowercased() == "true"
    let periodType = properties["rc_period_type"]?.lowercased()
    if periodType == "trial" { return .trial }
    if isSubscriber { return .paid }
    if properties["rc_subscriber"] == "false" { return .free }
    return nil
  }

  private func label(for status: BillingStatus) -> String {
    switch status {
    case .paid: return "Paid"
    case .trial: return "Trial"
    case .free: return "Free"
    }
  }
}
