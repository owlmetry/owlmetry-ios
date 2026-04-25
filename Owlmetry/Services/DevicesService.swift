import Foundation
import UIKit

enum DevicesService {
  /// Hex-encode the APNs device token Apple hands us as raw Data.
  static func hexToken(from data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
  }

  /// Register or refresh the current device's APNs token with the server.
  /// Token is the unique key — the server reassigns user_id atomically if
  /// the same token re-registers under a different user.
  static func register(token: String) async throws {
    struct Body: Encodable {
      let channel: String
      let token: String
      let environment: String
      let appVersion: String?
      let deviceModel: String?
      let osVersion: String?
    }
    struct Envelope: Decodable {
      let device: DeviceDTO
    }
    struct DeviceDTO: Decodable { let id: String }

    let body = Body(
      channel: "ios_push",
      token: token,
      environment: APNsEnvironment.current,
      appVersion: appVersion(),
      deviceModel: deviceModel(),
      osVersion: UIDevice.current.systemVersion
    )

    let _: Envelope = try await APIClient.shared.post("/v1/devices", body: body)
  }

  private static func appVersion() -> String? {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
  }

  private static func deviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)
    return mirror.children.compactMap { ($0.value as? Int8).flatMap { $0 == 0 ? nil : UnicodeScalar(UInt8($0)) } }
      .map { String($0) }
      .joined()
  }
}

enum APNsEnvironment {
  /// Reads `aps-environment` from the embedded provisioning profile so the
  /// reported environment matches the actual signing identity — `#if DEBUG`
  /// alone lies for Release-config builds signed with a Development cert
  /// (Xcode dev install of Release), where the token is sandbox but the
  /// compile flag says production.
  static var current: String {
    if let parsed = readFromProvisioningProfile() { return parsed }
    // App Store builds strip embedded.mobileprovision — fall back.
    #if DEBUG
    return "sandbox"
    #else
    return "production"
    #endif
  }

  private static func readFromProvisioningProfile() -> String? {
    guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
          let data = try? Data(contentsOf: url),
          let raw = String(data: data, encoding: .ascii),
          let keyRange = raw.range(of: "<key>aps-environment</key>") else {
      return nil
    }
    let tail = raw[keyRange.upperBound...]
    guard let stringStart = tail.range(of: "<string>"),
          let stringEnd = tail.range(of: "</string>", range: stringStart.upperBound..<tail.endIndex) else {
      return nil
    }
    let value = String(tail[stringStart.upperBound..<stringEnd.lowerBound])
    return value == "development" ? "sandbox" : "production"
  }
}
