import SwiftUI

// Hides on nil or 0 — keeps stable surfaces visually quiet.
struct DeltaText: View {
  enum Tone { case muted, colored }

  let delta: Int?
  let tone: Tone

  init(delta: Int?, tone: Tone = .colored) {
    self.delta = delta
    self.tone = tone
  }

  var body: some View {
    if let delta, delta != 0 {
      Text(formatted(delta))
        .font(.caption2.weight(.medium))
        .monospacedDigit()
        .foregroundStyle(color(for: delta))
    }
  }

  private func formatted(_ d: Int) -> String {
    // Negative values already include "-" from the formatter; only positives
    // need the explicit "+" prefix.
    d > 0 ? "+\(d.formatted(.number))" : d.formatted(.number)
  }

  private func color(for d: Int) -> Color {
    switch tone {
    case .muted: return .secondary
    case .colored: return d > 0 ? .green : .red
    }
  }
}
