import Owlmetry
import SwiftUI

struct RatingsListNavRoute: Hashable {}

struct RatingsView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = RatingsViewModel()

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        heroSection
        projectBreakdownSection
        countryBreakdownSection
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .navigationTitle("Ratings")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      if appState.projectsForCurrentTeam.count > 1 {
        ToolbarItem(placement: .topBarTrailing) { ProjectSelectorMenu() }
      }
    }
    .toolbar(.hidden, for: .tabBar)
    .refreshable { await reload() }
    .autoRefresh(id: refreshKey, every: 60) { await reload() }
    .task(id: refreshKey) { await reload() }
    .owlScreen("Ratings")
  }

  // MARK: Hero

  private var heroSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(scopeLabel.uppercased())
        .font(.system(size: 10, weight: .semibold))
        .tracking(0.8)
        .foregroundStyle(.secondary)
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        if let summary = scopedSummary {
          Text(String(format: "★ %.2f", summary.avg))
            .font(.system(size: 44, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.orange)
          Text("\(summary.total.formatted(.number)) ratings")
            .font(.callout)
            .foregroundStyle(.secondary)
        } else {
          Text("—")
            .font(.system(size: 44, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
          Text("No ratings yet")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
    }
    .padding(16)
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

  // MARK: By project

  @ViewBuilder
  private var projectBreakdownSection: some View {
    if appState.selectedProjectId == nil, projectRows.count >= 1 {
      VStack(alignment: .leading, spacing: 10) {
        sectionHeading("By project")
        VStack(spacing: 8) {
          ForEach(projectRows, id: \.project.id) { row in
            projectRow(row)
          }
        }
      }
    }
  }

  private func projectRow(_ row: ProjectRatingRow) -> some View {
    CardShell(accent: ProjectColor(project: row.project).base, padding: 12) {
      HStack(spacing: 12) {
        ProjectDot(project: row.project, size: 10)
        Text(row.project.name)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.primary)
          .lineLimit(1)
        Spacer(minLength: 0)
        if let avg = row.avg {
          RatingBadge(rating: avg, count: row.total, size: .sm)
        } else {
          Text("No ratings")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  // MARK: By country

  @ViewBuilder
  private var countryBreakdownSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionHeading("By country")
      switch viewModel.countriesState {
      case .loading where viewModel.countries.isEmpty:
        HStack { Spacer(); ProgressView(); Spacer() }
          .padding(.vertical, 24)
      case .error(let msg) where viewModel.countries.isEmpty:
        Text(msg)
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      case .empty:
        emptyCountriesView
      case .idle:
        EmptyView()
      default:
        countryGrid
      }
    }
  }

  private var emptyCountriesView: some View {
    HStack(spacing: 8) {
      Image(systemName: "globe")
        .foregroundStyle(.secondary)
      Text("No ratings synced yet.")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Theme.cardBackground)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Theme.cardBorder, lineWidth: 1)
    )
  }

  private var countryGrid: some View {
    let columns = [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)]
    let top = Array(viewModel.countries.prefix(20))
    return LazyVGrid(columns: columns, spacing: 10) {
      ForEach(top) { country in
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(CountryFlag.emoji(for: country.countryCode))
            Text(country.countryCode.uppercased())
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(format: "%.2f", country.averageRating))
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)
              .monospacedDigit()
            Image(systemName: "star.fill")
              .font(.caption2)
              .foregroundStyle(.orange)
            Text("(\(country.ratingCount.formatted(.number)))")
              .font(.caption)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Theme.cardBackground)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Theme.cardBorder, lineWidth: 1)
        )
      }
    }
  }

  // MARK: Helpers

  private func sectionHeading(_ text: String) -> some View {
    Text(text.uppercased())
      .font(.system(size: 10, weight: .semibold))
      .tracking(0.8)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 4)
  }

  private struct ProjectRatingRow {
    let project: Project
    let avg: Double?
    let total: Int
  }

  private var projectRows: [ProjectRatingRow] {
    appState.projectsForCurrentTeam.compactMap { project in
      let projectApps = appState.apps.filter { $0.projectId == project.id }
      let summary = ratingSummary(for: projectApps)
      return ProjectRatingRow(project: project, avg: summary?.avg, total: summary?.total ?? 0)
    }
    .filter { $0.total > 0 }
    .sorted { $0.total > $1.total }
  }

  private var scopedSummary: (avg: Double, total: Int)? {
    let scopedApps = appState.apps.filter {
      appState.selectedProjectId == nil || $0.projectId == appState.selectedProjectId
    }
    return ratingSummary(for: scopedApps)
  }

  private var scopeLabel: String {
    if let project = appState.selectedProject {
      return "\(project.name) · All time"
    }
    return "All apps · All time"
  }

  private func ratingSummary(for apps: [AppModel]) -> (avg: Double, total: Int)? {
    var weightedSum: Double = 0
    var total: Int = 0
    for app in apps {
      guard let rating = app.worldwideAverageRating, let count = app.worldwideRatingCount, count > 0 else { continue }
      weightedSum += rating * Double(count)
      total += count
    }
    guard total > 0 else { return nil }
    return (weightedSum / Double(total), total)
  }

  private var refreshKey: String {
    "\(appState.currentTeam?.id ?? "-")|\(appState.selectedProjectId ?? "all")"
  }

  private func reload() async {
    guard let teamId = appState.currentTeam?.id else { return }
    // Refresh apps too — the hero summary reads worldwide_* off the apps list,
    // which would otherwise stay frozen at whatever was loaded on app launch.
    async let countries: Void = viewModel.loadCountries(teamId: teamId, projectId: appState.selectedProjectId)
    async let apps: Void = appState.loadProjectsAndApps()
    _ = await (countries, apps)
  }
}
