import SwiftUI

struct AttributionBadge: View {
  let properties: [String: String]?
  var size: BadgeSize = .sm

  var body: some View {
    if let label {
      HStack(spacing: 4) {
        Text("🎯")
        Text(label)
      }
      .badgeStyle(tone: isSourced ? Theme.Attribution.sourced : Theme.Attribution.none, size: size)
    } else {
      EmptyView()
    }
  }

  private var source: String? {
    properties?["attribution_source"]
  }

  private var isSourced: Bool {
    guard let s = source else { return false }
    return !s.isEmpty && s != "none"
  }

  private var label: String? {
    guard let s = source else { return nil }
    switch s {
    case "apple_search_ads": return "ASA"
    case "meta": return "Meta"
    case "google_ads": return "Google"
    case "tiktok": return "TikTok"
    case "none", "": return nil
    default: return s
    }
  }
}
