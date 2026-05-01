import SwiftUI

struct AttributionBadge: View {
  let properties: [String: String]?
  var size: BadgeSize = .sm

  var body: some View {
    if let label {
      HStack(spacing: 4) {
        Text(emoji)
        Text(label)
      }
      .badgeStyle(tone: tone, size: size)
    } else {
      EmptyView()
    }
  }

  private var source: String? {
    properties?["attribution_source"]
  }

  private var isTestInstall: Bool {
    source == "apple_test_install"
  }

  private var isSourced: Bool {
    guard let s = source else { return false }
    return !s.isEmpty && s != "none" && s != "apple_test_install"
  }

  private var emoji: String {
    isTestInstall ? "🧪" : "🎯"
  }

  private var tone: Color {
    // Real ad attribution gets the accent color; test installs and any
    // non-attribution source render in the muted tone alongside organic.
    isSourced ? Theme.Attribution.sourced : Theme.Attribution.none
  }

  private var label: String? {
    guard let s = source else { return nil }
    switch s {
    case "apple_search_ads": return "ASA"
    case "apple_test_install": return "Test install"
    case "meta": return "Meta"
    case "google_ads": return "Google"
    case "tiktok": return "TikTok"
    case "none", "": return nil
    default: return s
    }
  }
}
