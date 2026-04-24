import Foundation

enum CountryFlag {
  static func emoji(for code: String?) -> String {
    guard let code, code.count == 2 else { return "🌐" }
    let base: UInt32 = 127_397
    var result = ""
    for scalar in code.uppercased().unicodeScalars {
      guard scalar.value >= 0x41, scalar.value <= 0x5A,
            let flagScalar = Unicode.Scalar(base + scalar.value) else { return "🌐" }
      result.unicodeScalars.append(flagScalar)
    }
    return result
  }
}
