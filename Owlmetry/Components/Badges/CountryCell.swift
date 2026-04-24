import SwiftUI

struct CountryCell: View {
  let code: String?
  var showCode: Bool = true

  var body: some View {
    HStack(spacing: 4) {
      Text(CountryFlag.emoji(for: code))
      if showCode, let code, !code.isEmpty {
        Text(code)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
}
