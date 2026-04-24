import SwiftUI

struct MetricPhaseBadge: View {
  let phase: MetricPhase
  var size: BadgeSize = .sm

  var body: some View {
    HStack(spacing: 4) {
      Text(phase.emoji)
      Text(phase.displayName)
    }
    .badgeStyle(tone: Theme.Phase.color(for: phase), size: size)
  }
}
