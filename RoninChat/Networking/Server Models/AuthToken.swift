import Foundation

open class AuthToken: Codable {
    public var userId: String!
    public var tokenType: String!
    public var accessToken: String!
    public var refreshToken: String!
    public var expiresIn: Int!
    
    public enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tokenType = "token_type"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
    
    public init(userId: String, tokenType: String, accessToken: String, refreshToken: String, expiresIn: Int) {
        self.userId = userId
        self.tokenType = tokenType
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}
