import Foundation

enum APIConfig {
  static let defaultBaseURL = "https://api.owlmetry.com"
  private static let overrideKey = "api.baseURL"

  static var baseURL: String {
    get {
      // Prefer the App Group mirror so the widget extension (which has its own
      // UserDefaults.standard) resolves the same backend the app is pointed at.
      if let shared = WidgetSharedStore.baseURLOverride, !shared.isEmpty { return shared }
      return UserDefaults.standard.string(forKey: overrideKey) ?? defaultBaseURL
    }
    set {
      let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      if trimmed.isEmpty || trimmed == defaultBaseURL {
        UserDefaults.standard.removeObject(forKey: overrideKey)
        WidgetSharedStore.baseURLOverride = nil
      } else {
        UserDefaults.standard.set(trimmed, forKey: overrideKey)
        WidgetSharedStore.baseURLOverride = trimmed
      }
    }
  }

  static var isOverridden: Bool {
    UserDefaults.standard.string(forKey: overrideKey) != nil
  }

  static func resetToDefault() {
    UserDefaults.standard.removeObject(forKey: overrideKey)
  }
}
