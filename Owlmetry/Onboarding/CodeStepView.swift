import SwiftUI

struct CodeStepView: View {
  @EnvironmentObject private var auth: AuthViewModel
  @State private var code: String = ""
  @FocusState private var isCodeFocused: Bool

  let onBack: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Spacer()
      codeField
      errorRow
      Spacer()
      CtaButton(
        title: "Verify",
        type: .primary,
        action: verifyAction
      )
      backButton
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 12)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        isCodeFocused = true
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Check your\nemail")
        .font(.system(size: 45, weight: .black))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 32)

      subtitle
    }
  }

  @ViewBuilder
  private var subtitle: some View {
    if let email = auth.pendingEmail {
      let prefix = Text("We sent a 6-digit code to ")
        .foregroundColor(.secondary)
      let emailText = Text(email)
        .foregroundColor(.primary)
        .fontWeight(.semibold)
      (prefix + emailText).font(.title3)
    } else {
      Text("We sent a 6-digit code to your email.")
        .font(.title3)
        .foregroundColor(.secondary)
    }
  }

  private var codeField: some View {
    UnderlinedTextField(
      placeholder: "123456",
      text: $code,
      isFocused: isCodeFocused,
      keyboardType: .numberPad,
      textContentType: .oneTimeCode,
      autocapitalization: .never,
      autocorrection: false
    )
    .focused($isCodeFocused)
    .onChange(of: code) { _, newValue in
      let digits = newValue.filter { $0.isNumber }
      let clamped = String(digits.prefix(6))
      if clamped != newValue { code = clamped }
      if auth.errorMessage != nil { auth.errorMessage = nil }
    }
  }

  @ViewBuilder
  private var errorRow: some View {
    if let error = auth.errorMessage {
      Text(error)
        .font(.caption)
        .foregroundColor(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
  }

  private var backButton: some View {
    Button {
      Haptics.play(.light)
      onBack()
    } label: {
      Text("Use a different email")
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.vertical, 8)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 4)
  }

  private var canSubmit: Bool { code.count == 6 }

  private var verifyAction: (() async -> Void)? {
    guard canSubmit else { return nil }
    return { await performVerify() }
  }

  private func performVerify() async {
    await auth.verifyCode(code)
    if auth.currentUser != nil {
      Haptics.notify(.success)
    }
  }
}
