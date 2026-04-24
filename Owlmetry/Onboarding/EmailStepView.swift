import Owlmetry
import SwiftUI

struct EmailStepView: View {
  @EnvironmentObject private var auth: AuthViewModel
  @State private var email: String = ""
  @State private var showServerSheet: Bool = false
  @FocusState private var isEmailFocused: Bool

  let onSent: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Spacer()
      emailField
      errorRow
      Spacer()
      CtaButton(
        title: "Continue",
        type: .primary,
        trailingIcon: "arrow.right",
        action: continueAction
      )
      serverButton
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 12)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        isEmailFocused = true
      }
    }
    .onChange(of: email) { _, _ in
      if auth.errorMessage != nil { auth.errorMessage = nil }
    }
    .sheet(isPresented: $showServerSheet) {
      ServerURLSheet()
    }
    .owlScreen("SignInEmail")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Welcome to\nOwlmetry")
        .font(.system(size: 45, weight: .black))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 32)

      Text("Sign in with your email to get started.")
        .font(.title3)
        .foregroundColor(.secondary)
    }
  }

  private var emailField: some View {
    UnderlinedTextField(
      placeholder: "you@example.com",
      text: $email,
      isFocused: isEmailFocused,
      keyboardType: .emailAddress,
      textContentType: .emailAddress,
      autocapitalization: .never,
      autocorrection: false
    )
    .focused($isEmailFocused)
    .onSubmit(submit)
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

  private var serverButton: some View {
    Button {
      showServerSheet = true
    } label: {
      Text(APIConfig.isOverridden ? "Using custom server" : "Use custom server")
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.vertical, 8)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 4)
  }

  private var canSubmit: Bool {
    email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@")
  }

  private var continueAction: (() async -> Void)? {
    guard canSubmit else { return nil }
    return { await performSend() }
  }

  private func submit() {
    guard canSubmit else { return }
    Task { await performSend() }
  }

  private func performSend() async {
    await auth.sendCode(email: email)
    if auth.errorMessage == nil && auth.pendingEmail != nil {
      isEmailFocused = false
      Haptics.notify(.success)
      onSent()
    }
  }
}
