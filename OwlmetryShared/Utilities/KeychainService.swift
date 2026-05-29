import Foundation
import Security

enum KeychainService {
  private static let service = "com.Owlmetry.auth"
  private static let account = "token"

  // Shared Keychain access group so the widget extension can read the same
  // token as the app. The literal must match `keychain-access-groups` in the
  // entitlements (`$(AppIdentifierPrefix)com.Owlmetry.shared`), with the
  // AppIdentifierPrefix resolved to the fixed team id (DEVELOPMENT_TEAM).
  private static let accessGroup = "8SY2WR6FV5.com.Owlmetry.shared"

  // One-time migration guard. Tokens saved before keychain sharing existed
  // live in the app's application-identifier group, which the widget can't
  // reach — move them into the shared group on first launch so existing users
  // aren't logged out and the widget works immediately.
  private static let migratedFlagKey = "owlmetry:keychain-migrated-v1"

  static func saveToken(_ token: String) {
    guard let data = token.data(using: .utf8) else { return }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
    ]

    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
    ]

    let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecItemNotFound {
      var addQuery = query
      addQuery.merge(attributes) { _, new in new }
      SecItemAdd(addQuery as CFDictionary, nil)
    }
  }

  static func token() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  static func deleteToken() {
    // Steady-state item in the shared group.
    SecItemDelete([
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
    ] as CFDictionary)
    // Also clear any pre-sharing legacy copy (application-identifier group) so
    // a stale token can't survive logout. A query with no access group reaches
    // every group the app can see.
    SecItemDelete([
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ] as CFDictionary)
  }

  /// Moves a pre-sharing token into the shared access group exactly once.
  /// Call before any `token()` read on launch (i.e. before `AuthViewModel`).
  static func migrateToSharedGroupIfNeeded() {
    let defaults = UserDefaults.standard
    guard !defaults.bool(forKey: migratedFlagKey) else { return }
    defer { defaults.set(true, forKey: migratedFlagKey) }

    // Already present in the shared group (already migrated, or signed in after
    // the update) — nothing to do.
    if token() != nil { return }

    // Find a legacy token. No access group → searches every group the app can
    // reach; since the shared group is empty (checked above), this only matches
    // the old application-identifier item.
    let legacyQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: AnyObject?
    guard SecItemCopyMatching(legacyQuery as CFDictionary, &result) == errSecSuccess,
          let data = result as? Data,
          let legacyToken = String(data: data, encoding: .utf8)
    else { return }

    // Re-add into the shared group. (The legacy copy is harmless and gets
    // swept by deleteToken on the next logout.)
    saveToken(legacyToken)
  }
}
