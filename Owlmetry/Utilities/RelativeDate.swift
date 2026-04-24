import Foundation

enum RelativeDate {
  private static let formatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    return f
  }()

  static func string(from iso: String?) -> String {
    guard let date = ISODate.parse(iso) else { return "—" }
    return formatter.localizedString(for: date, relativeTo: Date())
  }

  static func shortString(from iso: String?) -> String {
    guard let date = ISODate.parse(iso) else { return "—" }
    let seconds = Date().timeIntervalSince(date)
    if seconds < 60 { return "now" }
    if seconds < 3_600 { return "\(Int(seconds / 60))m" }
    if seconds < 86_400 { return "\(Int(seconds / 3_600))h" }
    if seconds < 604_800 { return "\(Int(seconds / 86_400))d" }
    if seconds < 2_592_000 { return "\(Int(seconds / 604_800))w" }
    return "\(Int(seconds / 2_592_000))mo"
  }
}
