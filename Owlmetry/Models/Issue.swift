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
  let authorType: String?
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

struct IssueDetail: Decodable {
  let issue: Issue
  let comments: [IssueComment]
  let occurrences: [IssueOccurrence]
  let occurrenceCursor: String?
  let occurrenceHasMore: Bool?
  let attachments: [IssueAttachment]?
  let fingerprints: [String]?

  private enum CodingKeys: String, CodingKey {
    case comments, occurrences, attachments, fingerprints
    case occurrenceCursor, occurrenceHasMore
  }

  init(from decoder: Decoder) throws {
    self.issue = try Issue(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.comments = try container.decodeIfPresent([IssueComment].self, forKey: .comments) ?? []
    self.occurrences = try container.decodeIfPresent([IssueOccurrence].self, forKey: .occurrences) ?? []
    self.occurrenceCursor = try container.decodeIfPresent(String.self, forKey: .occurrenceCursor)
    self.occurrenceHasMore = try container.decodeIfPresent(Bool.self, forKey: .occurrenceHasMore)
    self.attachments = try container.decodeIfPresent([IssueAttachment].self, forKey: .attachments)
    self.fingerprints = try container.decodeIfPresent([String].self, forKey: .fingerprints)
  }
}

struct IssuesListDTO: Decodable {
  let issues: [Issue]
  let cursor: String?
  let hasMore: Bool?
}
