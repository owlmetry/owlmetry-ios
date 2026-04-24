import SwiftUI

enum CtaButtonType {
  case primary
  case secondary
  case tertiary
}

struct CtaButton: View {
  var title: String
  var type: CtaButtonType
  var systemImage: String? = nil
  var trailingIcon: String? = nil
  var action: (() async -> Void)? = nil

  @State private var isPerformingTask = false
  @State private var showLoader = false
  @State private var isPressed = false

  var body: some View {
    titleComponent
      .foregroundColor(textColor)
      .frame(maxWidth: .infinity, maxHeight: 50)
      .background(
        RoundedRectangle(cornerRadius: 48)
          .fill(backgroundColor)
          .opacity(isPerformingTask ? 0.5 : 1)
      )
      .frame(height: 56)
      .contentShape(Rectangle())
      .scaleEffect(isPressed ? 0.97 : 1)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
      .if(
        action != nil,
        transform: { btn in
          btn
            .simultaneousGesture(
              DragGesture(minimumDistance: 0)
                .onChanged { _ in
                  isPressed = true
                }
                .onEnded { _ in
                  isPressed = false
                  guard let action else { return }
                  Haptics.play(.light)
                  startTask(task: action)
                }
            )
        }
      )
      .frame(maxWidth: 400)
      .frame(maxWidth: .infinity, alignment: .center)
      .accessibilityIdentifier(
        "cta_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
      )
      .accessibilityAddTraits(.isButton)
      .accessibilityLabel(title)
  }

  private var backgroundColor: Color {
    switch type {
    case .primary: return .accentColor
    case .secondary: return Color(.secondarySystemBackground)
    case .tertiary: return .clear
    }
  }

  private var textColor: Color {
    switch type {
    case .primary: return .white
    case .secondary: return .primary
    case .tertiary: return .accentColor
    }
  }

  var titleComponent: some View {
    Group {
      if showLoader {
        ProgressView()
          .tint(textColor)
          .transition(.opacity)
      } else if let trailingIcon {
        HStack(spacing: 6) {
          Text(title).fontWeight(.semibold)
          Image(systemName: trailingIcon)
        }
      } else if let systemImage {
        Label(title, systemImage: systemImage).fontWeight(.semibold)
      } else {
        Text(title).fontWeight(.semibold)
      }
    }
    .animation(.easeInOut(duration: 0.1), value: showLoader)
  }

  private func startTask(task: @escaping () async -> Void) {
    guard !isPerformingTask else { return }

    isPerformingTask = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      if isPerformingTask {
        showLoader = true
      }
    }

    Task {
      await task()
      isPerformingTask = false
      showLoader = false
    }
  }
}
