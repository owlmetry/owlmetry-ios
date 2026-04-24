import SwiftUI

struct EmptyState: View {
  let systemImage: String
  let title: String
  var subtitle: String? = nil
  var actionTitle: String? = nil
  var action: (() -> Void)? = nil

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.system(size: 36, weight: .light))
        .foregroundStyle(.secondary)
      Text(title)
        .font(.headline)
        .multilineTextAlignment(.center)
      if let subtitle {
        Text(subtitle)
          .font(.callout)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      if let actionTitle, let action {
        Button(actionTitle) { action() }
          .buttonStyle(.borderedProminent)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 32)
    .padding(.vertical, 48)
  }
}
