import Foundation

struct User: Codable, Equatable {
  let id: String
  let email: String
  let name: String
  let createdAt: String
  let updatedAt: String
}
