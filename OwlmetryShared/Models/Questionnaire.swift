import Foundation

// MARK: - Question schema

struct QuestionnaireChoiceOption: Codable, Equatable, Hashable, Identifiable {
  let id: String
  let label: String
}

enum QuestionnaireQuestion: Codable, Equatable, Hashable, Identifiable {
  case text(TextPayload)
  case singleChoice(ChoicePayload)
  case multiChoice(ChoicePayload)
  case rating(RatingPayload)
  case nps(BasePayload)
  case unknown(BasePayload)

  struct BasePayload: Codable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let required: Bool
  }

  struct TextPayload: Codable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let required: Bool
    let placeholder: String?
    let multiline: Bool?
  }

  struct ChoicePayload: Codable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let required: Bool
    let options: [QuestionnaireChoiceOption]
  }

  struct RatingPayload: Codable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let required: Bool
    let scale: Int
  }

  var id: String {
    switch self {
    case .text(let p): return p.id
    case .singleChoice(let p), .multiChoice(let p): return p.id
    case .rating(let p): return p.id
    case .nps(let p), .unknown(let p): return p.id
    }
  }

  var title: String {
    switch self {
    case .text(let p): return p.title
    case .singleChoice(let p), .multiChoice(let p): return p.title
    case .rating(let p): return p.title
    case .nps(let p), .unknown(let p): return p.title
    }
  }

  var subtitle: String? {
    switch self {
    case .text(let p): return p.subtitle
    case .singleChoice(let p), .multiChoice(let p): return p.subtitle
    case .rating(let p): return p.subtitle
    case .nps(let p), .unknown(let p): return p.subtitle
    }
  }

  private enum TypeKey: String, CodingKey { case type }

  init(from decoder: Decoder) throws {
    let typeContainer = try decoder.container(keyedBy: TypeKey.self)
    let type = try typeContainer.decode(String.self, forKey: .type)
    switch type {
    case "text":
      self = .text(try TextPayload(from: decoder))
    case "single_choice":
      self = .singleChoice(try ChoicePayload(from: decoder))
    case "multi_choice":
      self = .multiChoice(try ChoicePayload(from: decoder))
    case "rating":
      self = .rating(try RatingPayload(from: decoder))
    case "nps":
      self = .nps(try BasePayload(from: decoder))
    default:
      // Server may add new types ahead of the iOS app; render a placeholder
      // instead of failing the whole detail screen.
      self = .unknown(try BasePayload(from: decoder))
    }
  }

  func encode(to encoder: Encoder) throws {
    // Encoding isn't needed (read-only consumer) but Codable requires it.
    var c = encoder.container(keyedBy: TypeKey.self)
    switch self {
    case .text(let p):
      try c.encode("text", forKey: .type)
      try p.encode(to: encoder)
    case .singleChoice(let p):
      try c.encode("single_choice", forKey: .type)
      try p.encode(to: encoder)
    case .multiChoice(let p):
      try c.encode("multi_choice", forKey: .type)
      try p.encode(to: encoder)
    case .rating(let p):
      try c.encode("rating", forKey: .type)
      try p.encode(to: encoder)
    case .nps(let p):
      try c.encode("nps", forKey: .type)
      try p.encode(to: encoder)
    case .unknown(let p):
      try c.encode("unknown", forKey: .type)
      try p.encode(to: encoder)
    }
  }
}

struct QuestionnaireSchema: Codable, Equatable, Hashable {
  let version: Int
  let questions: [QuestionnaireQuestion]
}

// MARK: - Questionnaire spec

struct Questionnaire: Codable, Equatable, Hashable, Identifiable {
  let id: String
  let projectId: String
  let appId: String?
  let slug: String
  let name: String
  let description: String?
  let schema: QuestionnaireSchema
  let isActive: Bool
  let createdAt: String
  let updatedAt: String
  let responseCount: Int?
  let submittedCount: Int?
  let lastResponseAt: String?
}

struct QuestionnaireListDTO: Decodable {
  let questionnaires: [Questionnaire]
}

// MARK: - Answers

enum QuestionnaireAnswerValue: Codable, Equatable, Hashable {
  case string(String)
  case strings([String])
  case number(Int)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let s = try? container.decode(String.self) {
      self = .string(s)
    } else if let arr = try? container.decode([String].self) {
      self = .strings(arr)
    } else if let n = try? container.decode(Int.self) {
      self = .number(n)
    } else if let n = try? container.decode(Double.self) {
      self = .number(Int(n))
    } else {
      throw DecodingError.typeMismatch(
        QuestionnaireAnswerValue.self,
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Expected string, [String], or number for answer value"
        )
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .string(let s): try c.encode(s)
    case .strings(let arr): try c.encode(arr)
    case .number(let n): try c.encode(n)
    }
  }

  var asString: String? {
    if case .string(let s) = self { return s }
    return nil
  }

  var asStrings: [String]? {
    if case .strings(let arr) = self { return arr }
    return nil
  }

  var asNumber: Int? {
    if case .number(let n) = self { return n }
    return nil
  }
}

// MARK: - Response

enum QuestionnaireResponseStatus: String, Codable, CaseIterable, Identifiable {
  case draft
  case new
  case inReview = "in_review"
  case addressed
  case dismissed

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .draft: return "Draft"
    case .new: return "New"
    case .inReview: return "In Review"
    case .addressed: return "Addressed"
    case .dismissed: return "Dismissed"
    }
  }
}

struct QuestionnaireResponse: Codable, Equatable, Hashable, Identifiable {
  let id: String
  let questionnaireId: String
  let slug: String
  let appId: String?
  let projectId: String
  let sessionId: String?
  let userId: String?
  let answers: [String: QuestionnaireAnswerValue]
  let schemaSnapshot: QuestionnaireSchema?
  let submittedAt: String?
  let isComplete: Bool
  let status: QuestionnaireResponseStatus
  let isDev: Bool?
  let environment: String?
  let osVersion: String?
  let appVersion: String?
  let sdkName: String?
  let sdkVersion: String?
  let deviceModel: String?
  let countryCode: String?
  let createdAt: String
  let updatedAt: String
  let questionnaireName: String?
  let questionnaireSlug: String?
  let appName: String?
  let projectName: String?
  let userProperties: [String: String]?
}

struct QuestionnaireResponseComment: Codable, Equatable, Hashable, Identifiable {
  let id: String
  let questionnaireResponseId: String
  let authorType: String
  let authorId: String
  let authorName: String
  let body: String
  let createdAt: String
  let updatedAt: String
}

struct QuestionnaireResponseDetail: Decodable, Equatable, Hashable {
  let response: QuestionnaireResponse
  let comments: [QuestionnaireResponseComment]

  private enum CodingKeys: String, CodingKey {
    case comments
  }

  init(from decoder: Decoder) throws {
    response = try QuestionnaireResponse(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    comments = try container.decodeIfPresent([QuestionnaireResponseComment].self, forKey: .comments) ?? []
  }
}

struct QuestionnaireResponsesListDTO: Decodable {
  let responses: [QuestionnaireResponse]
  let cursor: String?
  let hasMore: Bool?
}

// MARK: - Analytics

struct QuestionnaireChoiceCount: Codable, Equatable, Hashable, Identifiable {
  let id: String
  let label: String
  let count: Int
}

struct QuestionnaireRatingBucket: Codable, Equatable, Hashable, Identifiable {
  let value: Int
  let count: Int
  var id: Int { value }
}

struct QuestionnaireTextRecentAnswer: Codable, Equatable, Hashable, Identifiable {
  let responseId: String
  let answer: String
  let createdAt: String
  var id: String { responseId }
}

enum QuestionnaireQuestionAnalytics: Decodable, Equatable, Hashable, Identifiable {
  case text(id: String, totalAnswered: Int, recentAnswers: [QuestionnaireTextRecentAnswer])
  case singleChoice(id: String, totalAnswered: Int, choices: [QuestionnaireChoiceCount])
  case multiChoice(id: String, totalAnswered: Int, choices: [QuestionnaireChoiceCount])
  case rating(id: String, totalAnswered: Int, average: Double?, buckets: [QuestionnaireRatingBucket])
  case nps(id: String, totalAnswered: Int, score: Double?, detractors: Int, passives: Int, promoters: Int, buckets: [QuestionnaireRatingBucket])
  case unknown(id: String)

  var id: String {
    switch self {
    case .text(let id, _, _),
         .singleChoice(let id, _, _),
         .multiChoice(let id, _, _),
         .rating(let id, _, _, _),
         .nps(let id, _, _, _, _, _, _),
         .unknown(let id):
      return id
    }
  }

  var totalAnswered: Int {
    switch self {
    case .text(_, let total, _),
         .singleChoice(_, let total, _),
         .multiChoice(_, let total, _),
         .rating(_, let total, _, _),
         .nps(_, let total, _, _, _, _, _):
      return total
    case .unknown: return 0
    }
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case type
    case totalAnswered
    case recentAnswers
    case choices
    case average
    case buckets
    case score
    case detractors
    case passives
    case promoters
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let id = try c.decode(String.self, forKey: .id)
    let type = try c.decode(String.self, forKey: .type)
    let totalAnswered = try c.decodeIfPresent(Int.self, forKey: .totalAnswered) ?? 0
    switch type {
    case "text":
      let recent = try c.decodeIfPresent([QuestionnaireTextRecentAnswer].self, forKey: .recentAnswers) ?? []
      self = .text(id: id, totalAnswered: totalAnswered, recentAnswers: recent)
    case "single_choice":
      let choices = try c.decodeIfPresent([QuestionnaireChoiceCount].self, forKey: .choices) ?? []
      self = .singleChoice(id: id, totalAnswered: totalAnswered, choices: choices)
    case "multi_choice":
      let choices = try c.decodeIfPresent([QuestionnaireChoiceCount].self, forKey: .choices) ?? []
      self = .multiChoice(id: id, totalAnswered: totalAnswered, choices: choices)
    case "rating":
      let avg = try c.decodeIfPresent(Double.self, forKey: .average)
      let buckets = try c.decodeIfPresent([QuestionnaireRatingBucket].self, forKey: .buckets) ?? []
      self = .rating(id: id, totalAnswered: totalAnswered, average: avg, buckets: buckets)
    case "nps":
      let score = try c.decodeIfPresent(Double.self, forKey: .score)
      let detractors = try c.decodeIfPresent(Int.self, forKey: .detractors) ?? 0
      let passives = try c.decodeIfPresent(Int.self, forKey: .passives) ?? 0
      let promoters = try c.decodeIfPresent(Int.self, forKey: .promoters) ?? 0
      let buckets = try c.decodeIfPresent([QuestionnaireRatingBucket].self, forKey: .buckets) ?? []
      self = .nps(id: id, totalAnswered: totalAnswered, score: score, detractors: detractors, passives: passives, promoters: promoters, buckets: buckets)
    default:
      self = .unknown(id: id)
    }
  }
}

struct QuestionnaireAnalytics: Decodable, Equatable, Hashable {
  let questionnaireId: String
  let slug: String
  let totalResponses: Int
  let submittedCount: Int
  let questions: [QuestionnaireQuestionAnalytics]
}
