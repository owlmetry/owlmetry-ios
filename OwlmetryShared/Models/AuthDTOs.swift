import Foundation

struct SendCodeRequest: Encodable {
  let email: String
}

struct SendCodeResponse: Decodable {
  let message: String
}

struct VerifyCodeRequest: Encodable {
  let email: String
  let code: String
}

struct VerifyCodeResponse: Decodable {
  let token: String
  let user: User
  let teams: [TeamMembership]
  let isNewUser: Bool
}

struct APIErrorBody: Decodable {
  let error: String
}
