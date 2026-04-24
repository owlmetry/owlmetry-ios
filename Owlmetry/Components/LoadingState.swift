import SwiftUI

struct LoadingState: View {
  var message: String? = nil

  var body: some View {
    VStack(spacing: 12) {
      ProgressView()
      if let message {
        Text(message)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }
}
