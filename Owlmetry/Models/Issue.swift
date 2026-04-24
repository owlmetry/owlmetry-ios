import Foundation

struct Issue: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String
  let appId: String?
  let title: String
  let fingerprint: String?
  let status: IssueStatus
  let occurrenceCount: Int
  let uniqueUserCount: Int
  let firstSeenAt: String
  let lastSeenAt: String
  let firstSeenAppVersion: String?
  let lastSeenAppVersion: String?
  let resolvedAtVersion: String?
  let isDev: Bool?
  let source: String?
  let environment: String?
  let createdAt: String
  let updatedAt: String
}

struct IssueOccurrence: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let issueId: String
  let eventId: String?
  let sessionId: String?
  let userId: String?
  let appVersion: String?
  let environment: String?
  let countryCode: String?
  let timestamp: String
}

struct IssueComment: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let issueId: String
  let authorId: String?
  let authorName: String?
  let body: String
  let createdAt: String
}

struct IssueAttachment: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let filename: String
  let contentType: String?
  let sizeBytes: Int?
  let createdAt: String
}

struct IssueDetail: Codable, Equatable, Hashable {
  let issue: Issue
  let comments: [IssueComment]
  let occurrences: [IssueOccurrence]
  let occurrenceCursor: String?
  let hasMoreOccurrences: Bool?
  let attachments: [IssueAttachment]?
  let fingerprints: [String]?
}

struct IssuesListDTO: Decodable {
  let issues: [Issue]
  let cursor: String?
  let hasMore: Bool?
}
