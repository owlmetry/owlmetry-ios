import SwiftUI

struct StatCard: View {
  let label: String
  let systemImage: String
  let value: String
  var isLoading: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top) {
        Text(label.uppercased())
          .font(.system(size: 10, weight: .semibold))
          .tracking(0.8)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        Spacer(minLength: 0)
        Image(systemName: systemImage)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
      }
      if isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Text(value)
          .font(.system(size: 34, weight: .semibold, design: .default))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .foregroundStyle(.primary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Theme.cardBackground)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Theme.cardBorder, lineWidth: 1)
    )
  }
}
