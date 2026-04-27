import Foundation

struct Review: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let appId: String
  let appName: String
  let projectId: String
  let store: ReviewStore
  let externalId: String
  let rating: Int
  let title: String?
  let body: String
  let reviewerName: String?
  let countryCode: String?
  let appVersion: String?
  let languageCode: String?
  let developerResponse: String?
  let developerResponseAt: String?
  let createdAtInStore: String
  let ingestedAt: String
}

enum ReviewStore: String, Codable, CaseIterable, Identifiable {
  case appStore = "app_store"
  case playStore = "play_store"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .appStore: return "🍎 App Store"
    case .playStore: return "🤖 Play Store"
    }
  }

  var shortName: String {
    switch self {
    case .appStore: return "App Store"
    case .playStore: return "Play Store"
    }
  }
}

struct ReviewsListDTO: Decodable {
  let reviews: [Review]
  let cursor: String?
  let hasMore: Bool?
}

struct ReviewsByCountrySummary: Codable, Identifiable, Equatable, Hashable {
  let countryCode: String
  let reviewCount: Int
  let averageRating: Double

  var id: String { countryCode }
}

struct ReviewsByCountryDTO: Decodable {
  let countries: [ReviewsByCountrySummary]
}

struct ReviewFilter: Equatable {
  var appId: String?
  var store: ReviewStore?
  var rating: Int?
  var search: String = ""

  var hashDescription: String {
    "\(appId ?? "-")|\(store?.rawValue ?? "-")|\(rating.map(String.init) ?? "-")|\(search)"
  }
}
