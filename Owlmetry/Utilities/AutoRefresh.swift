import SwiftUI

struct AutoRefreshModifier<ID: Equatable>: ViewModifier {
  let id: ID
  let interval: TimeInterval
  let action: () async -> Void

  @Environment(\.scenePhase) private var scenePhase

  func body(content: Content) -> some View {
    content
      .task(id: RefreshKey(id: id, phase: scenePhase)) {
        await action()
        guard scenePhase == .active else { return }
        while !Task.isCancelled {
          do {
            try await Task.sleep(for: .seconds(interval))
          } catch {
            return
          }
          if Task.isCancelled { return }
          await action()
        }
      }
  }

  private struct RefreshKey: Equatable {
    let id: ID
    let phase: ScenePhase
  }
}

extension View {
  func autoRefresh<ID: Equatable>(id: ID, every interval: TimeInterval, action: @escaping () async -> Void) -> some View {
    modifier(AutoRefreshModifier(id: id, interval: interval, action: action))
  }
}
