import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject private var auth: AuthViewModel
  @State private var currentPage: Int = 0

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      TabView(selection: $currentPage) {
        IntroView(onContinue: {
          withAnimation(.easeInOut) { currentPage = 1 }
        })
        .tag(0)

        FeaturesView(onContinue: {
          withAnimation(.easeInOut) { currentPage = 2 }
        })
        .tag(1)

        EmailStepView(onSent: {
          withAnimation(.easeInOut) { currentPage = 3 }
        })
        .tag(2)

        CodeStepView(onBack: {
          auth.clearPendingEmail()
          withAnimation(.easeInOut) { currentPage = 2 }
        })
        .tag(3)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
    }
    .onChange(of: auth.pendingEmail) { _, newValue in
      if newValue == nil && currentPage == 3 {
        withAnimation(.easeInOut) { currentPage = 2 }
      }
    }
  }
}
