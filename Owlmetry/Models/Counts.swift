import Foundation

struct EventsCountResponse: Decodable, Equatable {
  let count: Int
  let uniqueUsers: Int
  let uniqueSessions: Int
}

struct CompletionsCountResponse: Decodable, Equatable {
  let count: Int
  let started: Int?
}
