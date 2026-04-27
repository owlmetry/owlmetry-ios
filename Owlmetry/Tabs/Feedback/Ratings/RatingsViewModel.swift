import Combine
import Foundation
import Owlmetry

@MainActor
final class RatingsViewModel: ObservableObject {
  @Published var countriesState: Loadable<Void> = .idle
  @Published private(set) var countries: [RatingsByCountrySummary] = []

  // Backed by app_store_ratings (true storefront ratings, incl. star-only)
  // — replaces the old reviews-by-country source which only counted users
  // who left a written review.
  func loadCountries(teamId: String, projectId: String?) async {
    countriesState = .loading
    do {
      let dto = try await RatingsService.byCountry(teamId: teamId, projectId: projectId)
      countries = dto.countries
      countriesState = countries.isEmpty ? .empty : .loaded(())
    } catch let error as APIError {
      countriesState = .error(error.errorDescription ?? "Failed to load countries")
      Owl.error("ratings.countries.failed", attributes: ["error": "\(error)"])
    } catch {
      if error.isCancellation { return }
      countriesState = .error(error.localizedDescription)
      Owl.error("ratings.countries.failed", attributes: ["error": "\(error)"])
    }
  }
}
