import SwiftUI

struct FeaturesView: View {
  let onContinue: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Spacer(minLength: 24)
      features
      Spacer(minLength: 24)
      CtaButton(
        title: "Get started",
        type: .primary,
        trailingIcon: "arrow.right",
        action: { onContinue() }
      )
    }
    .padding(.horizontal, 24)
    .padding(.top, 32)
    .padding(.bottom, 12)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Stay\nin the loop.")
        .font(.system(size: 44, weight: .black))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("Check what's happening across your apps — anywhere.")
        .font(.title3)
        .foregroundColor(.secondary)
    }
  }

  private var features: some View {
    VStack(alignment: .leading, spacing: 24) {
      featureRow(
        icon: "bubble.left.and.bubble.right.fill",
        title: "User feedback",
        description: "Hear from users directly inside your app."
      )
      featureRow(
        icon: "ant.fill",
        title: "Issues & crashes",
        description: "Error events cluster into issues automatically, with semver-aware regression detection."
      )
      featureRow(
        icon: "waveform.path.ecg",
        title: "Events & performance",
        description: "Structured events, metrics and funnels give you a complete picture of every user journey."
      )
    }
  }

  private func featureRow(icon: String, title: String, description: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.accentColor.opacity(0.12))
          .frame(width: 40, height: 40)
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.accentColor)
      }

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.headline)
        Text(description)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
