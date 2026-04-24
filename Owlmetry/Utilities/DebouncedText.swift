import Combine
import Foundation

@MainActor
final class DebouncedText: ObservableObject {
  @Published var text: String = ""
  @Published private(set) var debounced: String = ""

  private var cancellable: AnyCancellable?

  init(delay: TimeInterval = 0.35) {
    cancellable = $text
      .removeDuplicates()
      .debounce(for: .seconds(delay), scheduler: DispatchQueue.main)
      .sink { [weak self] value in
        self?.debounced = value
      }
  }
}
