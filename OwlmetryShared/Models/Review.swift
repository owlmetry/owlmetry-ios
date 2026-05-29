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
  let developerResponseId: String?
  let developerResponseState: ReviewResponseState?
  let respondedByUserId: String?
  let createdAtInStore: String
  let ingestedAt: String
}

enum ReviewResponseState: String, Codable, Hashable {
  case published = "PUBLISHED"
  case pendingPublish = "PENDING_PUBLISH"

  var displayLabel: String {
    switch self {
    case .published: return "Published"
    case .pendingPublish: return "Pending publish"
    }
  }
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

struct ReviewFilter: Equatable {
  var appId: String?
  var store: ReviewStore?
  var rating: Int?
  var search: String = ""

  var hashDescription: String {
    "\(appId ?? "-")|\(store?.rawValue ?? "-")|\(rating.map(String.init) ?? "-")|\(search)"
  }
}
