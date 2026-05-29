import SwiftUI

struct ProjectColor: Equatable, Hashable {
  static let fallbackHex = "#64748b"

  let hex: String
  let base: Color

  init(hex: String?) {
    let value = hex ?? ProjectColor.fallbackHex
    self.hex = value
    self.base = Color(hex: value) ?? Color(hex: ProjectColor.fallbackHex) ?? .gray
  }

  init(project: Project?) {
    self.init(hex: project?.color)
  }

  var backgroundFill: Color { base.opacity(0.10) }
  var borderStroke: Color { base.opacity(0.30) }
  var foreground: Color { base }
}

extension Color {
  init?(hex: String) {
    var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleaned.hasPrefix("#") { cleaned.removeFirst() }
    guard cleaned.count == 6 || cleaned.count == 8 else { return nil }
    var value: UInt64 = 0
    guard Scanner(string: cleaned).scanHexInt64(&value) else { return nil }
    let r, g, b, a: Double
    if cleaned.count == 6 {
      r = Double((value & 0xFF_00_00) >> 16) / 255
      g = Double((value & 0x00_FF_00) >> 8) / 255
      b = Double(value & 0x00_00_FF) / 255
      a = 1
    } else {
      r = Double((value & 0xFF_00_00_00) >> 24) / 255
      g = Double((value & 0x00_FF_00_00) >> 16) / 255
      b = Double((value & 0x00_00_FF_00) >> 8) / 255
      a = Double(value & 0x00_00_00_FF) / 255
    }
    self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
  }
}
