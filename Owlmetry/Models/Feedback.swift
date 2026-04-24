import Foundation

struct Feedback: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String
  let appId: String?
  let status: FeedbackStatus
  let message: String
  let submitterName: String?
  let submitterEmail: String?
  let userId: String?
  let sessionId: String?
  let appVersion: String?
  let environment: String?
  let deviceModel: String?
  let osVersion: String?
  let countryCode: String?
  let isDev: Bool?
  let userProperties: [String: String]?
  let createdAt: String
  let updatedAt: String
}

struct FeedbackComment: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let feedbackId: String
  let authorId: String?
  let authorName: String?
  let body: String
  let createdAt: String
}

struct FeedbackDetail: Codable, Equatable, Hashable {
  let feedback: Feedback
  let comments: [FeedbackComment]
}

struct FeedbackListDTO: Decodable {
  let feedback: [Feedback]
  let cursor: String?
  let hasMore: Bool?
}
