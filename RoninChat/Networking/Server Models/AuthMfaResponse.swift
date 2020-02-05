import Foundation

open class AuthMfaResponse: Codable {
    public var error: String!
    public var mfaToken: String!
    public var description: String!
    
    public enum CodingKeys: String, CodingKey {
        case error = "error"
        case mfaToken = "mfa_token"
        case description = "error_description"
    }
    
    public init(error: String, description: String, mfaToken: String) {
        self.error = error
        self.description = description
        self.mfaToken = mfaToken
    }
}
