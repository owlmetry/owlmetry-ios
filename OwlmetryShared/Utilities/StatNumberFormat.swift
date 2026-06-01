import Foundation

/// Compact display string for the dashboard stat tiles. Mirrors the web
/// `formatStatNumber` (apps/web/src/lib/format-number.ts) so both surfaces read
/// identically:
///
/// - Below 100,000: locale thousands separators (`11832` → `11,832`) so smaller
///   numbers stay exact and readable.
/// - 100,000 and up: abbreviate to a short suffixed form (`408885` → `409k`,
///   `1_250_000` → `1.3M`) so headline numbers can't overflow the fixed tile width.
///
/// The 100k threshold matches the point where un-separated numbers start to get
/// long; `99,999` still renders in full, `100k` and beyond compress.
enum StatNumberFormat {
  static func string(_ value: Int) -> String {
    let v = Double(value)
    let magnitude = Swift.abs(v)

    // Roll up to the next unit once rounding would otherwise print e.g. "1000k".
    if magnitude >= 999_500_000_000 { return trimUnit(v / 1_000_000_000_000) + "T" }
    if magnitude >= 999_500_000 { return trimUnit(v / 1_000_000_000) + "B" }
    if magnitude >= 999_500 { return trimUnit(v / 1_000_000) + "M" }
    if magnitude >= 100_000 { return "\(Int((v / 1_000).rounded()))k" }

    return value.formatted(.number)
  }

  /// One decimal below 10× the unit (`1.3M`), whole numbers above (`12M`); drops a trailing `.0`.
  private static func trimUnit(_ scaled: Double) -> String {
    guard Swift.abs(scaled) < 10 else { return "\(Int(scaled.rounded()))" }
    let fixed = String(format: "%.1f", scaled)
    return fixed.hasSuffix(".0") ? String(fixed.dropLast(2)) : fixed
  }
}
