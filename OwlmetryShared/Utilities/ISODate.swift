import Foundation

enum ISODate {
  private static let withFractional: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
  }()

  private static let plain: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
  }()

  static func parse(_ value: String?) -> Date? {
    guard let value else { return nil }
    return withFractional.date(from: value) ?? plain.date(from: value)
  }

  static func format(_ value: String?, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
    guard let date = parse(value) else { return "—" }
    let f = DateFormatter()
    f.dateStyle = dateStyle
    f.timeStyle = timeStyle
    return f.string(from: date)
  }

  static func isoString(since seconds: TimeInterval) -> String {
    let d = Date().addingTimeInterval(-seconds)
    return plain.string(from: d)
  }

  static func now() -> String {
    plain.string(from: Date())
  }
}
