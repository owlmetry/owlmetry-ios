import SwiftUI

struct IntroView: View {
  let onContinue: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer(minLength: 24)

      hero

      Spacer(minLength: 24)

      headline

      Spacer(minLength: 32)

      CtaButton(
        title: "Continue",
        type: .primary,
        trailingIcon: "arrow.right",
        action: { onContinue() }
      )
    }
    .padding(.horizontal, 24)
    .padding(.top, 32)
    .padding(.bottom, 12)
  }

  private var hero: some View {
    ZStack {
      Circle()
        .fill(Color.accentColor.opacity(0.18))
        .frame(width: 260, height: 260)
        .blur(radius: 48)

      Image("OwlLogo")
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 140, height: 140)
        .foregroundStyle(Color.accentColor)
        .shadow(color: Color.accentColor.opacity(0.45), radius: 28, x: 0, y: 0)
    }
    .frame(maxWidth: .infinity)
  }

  private var headline: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Agent-first\nobservability.")
        .font(.system(size: 44, weight: .black))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("Structured events, metrics, funnels, feedback and issues — purpose-built for your coding agent, ready to glance at from your pocket.")
        .font(.title3)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
