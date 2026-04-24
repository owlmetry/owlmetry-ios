import Foundation

enum APIConfig {
  static let defaultBaseURL = "https://api.owlmetry.com"
  private static let overrideKey = "api.baseURL"

  static var baseURL: String {
    get { UserDefaults.standard.string(forKey: overrideKey) ?? defaultBaseURL }
    set {
      let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      if trimmed.isEmpty || trimmed == defaultBaseURL {
        UserDefaults.standard.removeObject(forKey: overrideKey)
      } else {
        UserDefaults.standard.set(trimmed, forKey: overrideKey)
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
