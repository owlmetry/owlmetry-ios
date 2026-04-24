import Owlmetry
import SwiftUI

struct InsightsView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        NavigationLink {
          MetricsListView()
        } label: {
          InsightTile(
            title: "Metrics",
            subtitle: "Track start / complete / fail / cancel / record events with durations and success rates.",
            systemImage: "chart.bar",
            tone: Color.blue
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          FunnelsListView()
        } label: {
          InsightTile(
            title: "Funnels",
            subtitle: "See where users drop off across a sequence of steps.",
            systemImage: "line.3.horizontal.decrease.circle",
            tone: Color.purple
          )
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .navigationTitle("Insights")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
    }
    .owlScreen("Insights")
  }
}

private struct InsightTile: View {
  let title: String
  let subtitle: String
  let systemImage: String
  let tone: Color

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      ZStack {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(tone.opacity(0.12))
        Image(systemName: systemImage)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(tone)
      }
      .frame(width: 44, height: 44)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .foregroundStyle(.primary)
        Text(subtitle)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.top, 12)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Theme.cardBackground)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Theme.cardBorder, lineWidth: 1)
    )
  }
}
