import Foundation
import Owlmetry

enum APIError: Error, LocalizedError {
  case http(status: Int, message: String)
  case decoding(Error)
  case transport(Error)
  case invalidURL

  var errorDescription: String? {
    switch self {
    case .http(_, let message): return message
    case .decoding: return "Unexpected response from server."
    case .transport: return "Network error — please try again."
    case .invalidURL: return "Invalid server URL."
    }
  }

  var metricAttributes: [String: String] {
    switch self {
    case .http(let status, _): return ["kind": "http", "status": "\(status)"]
    case .decoding: return ["kind": "decoding"]
    case .transport: return ["kind": "transport"]
    case .invalidURL: return ["kind": "invalid_url"]
    }
  }
}

struct APIClient {
  static let shared = APIClient()

  private let session: URLSession = .shared
  private let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.keyEncodingStrategy = .convertToSnakeCase
    return e
  }()
  private let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    return d
  }()

  func post<Req: Encodable, Res: Decodable>(_ path: String, body: Req) async throws -> Res {
    try await request(path: path, method: "POST", body: body, query: [:])
  }

  func get<Res: Decodable>(_ path: String) async throws -> Res {
    try await request(path: path, method: "GET", body: Optional<Empty>.none, query: [:])
  }

  func get<Res: Decodable>(_ path: String, query: [String: String?]) async throws -> Res {
    try await request(path: path, method: "GET", body: Optional<Empty>.none, query: query)
  }

  func patch<Req: Encodable, Res: Decodable>(_ path: String, body: Req) async throws -> Res {
    try await request(path: path, method: "PATCH", body: body, query: [:])
  }

  func patchNoBody<Res: Decodable>(_ path: String) async throws -> Res {
    try await request(path: path, method: "PATCH", body: Optional<Empty>.none, query: [:])
  }

  func delete<Res: Decodable>(_ path: String) async throws -> Res {
    try await request(path: path, method: "DELETE", body: Optional<Empty>.none, query: [:])
  }

  private struct Empty: Encodable {}

  private func request<Req: Encodable, Res: Decodable>(
    path: String,
    method: String,
    body: Req?,
    query: [String: String?]
  ) async throws -> Res {
    let op = Owl.startOperation("api-call", attributes: [
      "method": method,
      "path": path,
    ])

    guard let url = buildURL(path: path, query: query) else {
      op.fail(error: "invalid_url", attributes: ["kind": "invalid_url"])
      throw APIError.invalidURL
    }

    var req = URLRequest(url: url)
    req.httpMethod = method
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("application/json", forHTTPHeaderField: "Accept")

    if let token = KeychainService.token() {
      req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    if let body {
      do {
        req.httpBody = try encoder.encode(body)
      } catch {
        op.fail(error: "\(error)", attributes: ["kind": "encoding"])
        throw APIError.decoding(error)
      }
    }

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: req)
    } catch {
      op.fail(error: "\(error)", attributes: ["kind": "transport"])
      throw APIError.transport(error)
    }

    guard let http = response as? HTTPURLResponse else {
      op.fail(error: "bad_server_response", attributes: ["kind": "transport"])
      throw APIError.transport(URLError(.badServerResponse))
    }

    if !(200..<300).contains(http.statusCode) {
      let message: String
      if let body = try? decoder.decode(APIErrorBody.self, from: data) {
        message = body.error
      } else {
        message = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
      }
      let err = APIError.http(status: http.statusCode, message: message)
      op.fail(error: message, attributes: err.metricAttributes)
      throw err
    }

    do {
      let decoded = try decoder.decode(Res.self, from: data)
      op.complete(attributes: ["status": "\(http.statusCode)"])
      return decoded
    } catch {
      op.fail(error: "\(error)", attributes: ["kind": "decoding"])
      throw APIError.decoding(error)
    }
  }

  private func buildURL(path: String, query: [String: String?]) -> URL? {
    guard var components = URLComponents(string: APIConfig.baseURL + path) else {
      return nil
    }
    let items = query
      .compactMap { (key, value) -> URLQueryItem? in
        guard let value, !value.isEmpty else { return nil }
        return URLQueryItem(name: key, value: value)
      }
      .sorted { $0.name < $1.name }
    if !items.isEmpty {
      components.queryItems = items
    }
    return components.url
  }
}
