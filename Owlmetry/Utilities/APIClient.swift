import Foundation

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
    try await request(path: path, method: "POST", body: body)
  }

  func get<Res: Decodable>(_ path: String) async throws -> Res {
    try await request(path: path, method: "GET", body: Optional<Empty>.none)
  }

  private struct Empty: Encodable {}

  private func request<Req: Encodable, Res: Decodable>(path: String, method: String, body: Req?) async throws -> Res {
    guard let url = URL(string: APIConfig.baseURL + path) else {
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
        throw APIError.decoding(error)
      }
    }

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: req)
    } catch {
      throw APIError.transport(error)
    }

    guard let http = response as? HTTPURLResponse else {
      throw APIError.transport(URLError(.badServerResponse))
    }

    if !(200..<300).contains(http.statusCode) {
      let message: String
      if let body = try? decoder.decode(APIErrorBody.self, from: data) {
        message = body.error
      } else {
        message = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
      }
      throw APIError.http(status: http.statusCode, message: message)
    }

    do {
      return try decoder.decode(Res.self, from: data)
    } catch {
      throw APIError.decoding(error)
    }
  }
}
