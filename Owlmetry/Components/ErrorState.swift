import SwiftUI

struct ErrorState: View {
  let message: String
  var retry: (() -> Void)? = nil

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 32, weight: .light))
        .foregroundStyle(.orange)
      Text("Something went wrong")
        .font(.headline)
      Text(message)
        .font(.callout)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      if let retry {
        Button("Retry") { retry() }
          .buttonStyle(.bordered)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 32)
    .padding(.vertical, 32)
  }
}
