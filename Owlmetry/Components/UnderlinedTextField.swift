import SwiftUI

struct UnderlinedTextField: View {
  let placeholder: String
  @Binding var text: String
  var isFocused: Bool
  var keyboardType: UIKeyboardType = .default
  var textContentType: UITextContentType? = nil
  var autocapitalization: TextInputAutocapitalization = .sentences
  var autocorrection: Bool = true

  var body: some View {
    TextField(placeholder, text: $text)
      .font(.title)
      .padding(.vertical, 12)
      .padding(.top, 20)
      .keyboardType(keyboardType)
      .textContentType(textContentType)
      .textInputAutocapitalization(autocapitalization)
      .autocorrectionDisabled(!autocorrection)
      .overlay(
        Rectangle()
          .frame(height: 2)
          .foregroundColor(isFocused ? .accentColor : Color.gray.opacity(0.3)),
        alignment: .bottom
      )
      .padding(.bottom, 40)
  }
}
