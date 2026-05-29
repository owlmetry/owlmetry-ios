import Foundation

struct Issue: Codable, Identifiable, Equatable, Hashable {
  let id: String
  let projectId: String
  let appId: String?
  let title: String
  let fingerprints: [String]?
  let status: IssueStatus
  let occurrenceCount: Int
  let uniqueUserCount: Int
  let firstSeenAt: String
  let lastSeenAt: String
  let firstSeenAppVersion: String?
  let lastSeenAppVersion: String?
  let resolvedAtVersion: String?
  let isDev: Bool?
  let sourceModule: String?
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
  let originalFilename: String
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
  let decodeFailures: [DecodeFailure]
  let cursor: String?
  let hasMore: Bool?

  struct DecodeFailure {
    let index: Int
    let reason: String
  }

  private enum CodingKeys: String, CodingKey {
    case issues, cursor, hasMore
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let raw = try container.decode([FailableIssue].self, forKey: .issues)
    var decoded: [Issue] = []
    var failures: [DecodeFailure] = []
    decoded.reserveCapacity(raw.count)
    for (index, item) in raw.enumerated() {
      switch item.outcome {
      case .value(let issue): decoded.append(issue)
      case .failure(let summary): failures.append(DecodeFailure(index: index, reason: summary))
      }
    }
    self.issues = decoded
    self.decodeFailures = failures
    self.cursor = try container.decodeIfPresent(String.self, forKey: .cursor)
    self.hasMore = try container.decodeIfPresent(Bool.self, forKey: .hasMore)
  }
}

private struct FailableIssue: Decodable {
  enum Outcome {
    case value(Issue)
    case failure(String)
  }
  let outcome: Outcome

  init(from decoder: Decoder) throws {
    do {
      self.outcome = .value(try Issue(from: decoder))
    } catch {
      self.outcome = .failure(DecodingFailureSummary.string(from: error))
    }
  }
}

enum DecodingFailureSummary {
  static func string(from error: Error) -> String {
    guard let decErr = error as? DecodingError else {
      return String(describing: error).prefix(160).description
    }
    switch decErr {
    case .typeMismatch(let type, let ctx):
      return "typeMismatch \(type) at \(path(ctx.codingPath)): \(ctx.debugDescription)".prefix(160).description
    case .valueNotFound(let type, let ctx):
      return "valueNotFound \(type) at \(path(ctx.codingPath))".prefix(160).description
    case .keyNotFound(let key, let ctx):
      return "keyNotFound \(key.stringValue) at \(path(ctx.codingPath))".prefix(160).description
    case .dataCorrupted(let ctx):
      return "dataCorrupted at \(path(ctx.codingPath)): \(ctx.debugDescription)".prefix(160).description
    @unknown default:
      return String(describing: decErr).prefix(160).description
    }
  }

  private static func path(_ path: [CodingKey]) -> String {
    path.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: ".")
  }
}
