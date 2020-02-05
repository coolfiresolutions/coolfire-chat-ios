import Foundation

open class ConversationsApi: ServerApi {
    public lazy var userGroupsUrl = apiUrl + userGroupsPath
    
    override public init() {}
    
    public func getAllConversationsUrl(_ networkId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(conversationsPath)"
    }
    
    public func getUserConversationUrl(_ networkId: String, _ userId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(userProfilePath)\(usersPath)\(userId)"
    }
    
    public func getUserGroupConversationUrl(_ networkId: String, _ userGroupId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(userProfilePath)\(userGroupsPath)\(userGroupId)"
    }
    
    public func getUserGroupUrl(_ userGroupId: String) -> String {
        return "\(apiUrl)\(userGroupsPath)\(userGroupId)"
    }
    
    
    // MARK: - API
    
    public func getConversations(networkId: String, completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        let url = getAllConversationsUrl(networkId)
        
        RoninServerInterface.shared.getObjects(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackConversations(dictionaryArray)))
            }
        })
    }
    
    public func createUserGroup(parameters: [String: Any], completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: userGroupsUrl, httpMethod: .post, parameters: parameters)
        
        RoninServerInterface.shared.getObject(with: urlRequest, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionary): completion(.success(self.unpackUserGroup(dictionary)))
            }
        })
    }
    
    public func removeUserConversation(networkId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let url = getUserConversationUrl(networkId, userId)
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: url, httpMethod: .delete, parameters: [:])
        
        RoninServerInterface.shared.perform(with: urlRequest, completion: completion)
    }
    
    public func removeUserGroupConversation(networkId: String, groupId: String, parameters: [String: Any], completion: @escaping (Bool) -> Void) {
        let url = getUserGroupConversationUrl(networkId, groupId)
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: url, httpMethod: .put, parameters: parameters)
        
        RoninServerInterface.shared.perform(with: urlRequest, completion: completion)
    }
    
    public func patchUserGroup(_ userGroupId: String, parameters: [String: Any], completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        let url = getUserGroupUrl(userGroupId)
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: url, httpMethod: .patch, parameters: parameters)
        
        RoninServerInterface.shared.getObject(with: urlRequest, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionary): completion(.success(self.unpackUserGroup(dictionary)))
            }
        })
    }
    
    
    // MARK: - Utility
    
    open func unpackUserGroup(_ dictionary: [String: Any]) -> AnyObject? {
        return UserGroup(fromDictionary: dictionary)
    }
    
    open func unpackConversations(_ dictionaryArray: [[String: Any]]) -> [AnyObject] {
        var conversations = [Messageable]()
        
        for dictionary in dictionaryArray {
            guard let targetType = dictionary["tgtType"] as? String else {
                continue
            }
            
            switch targetType {
            case RoninMessage.ScopeType.User.rawValue:
                if let conversation = User(fromDictionary: dictionary) {
                    conversations.append(conversation)
                }
            case RoninMessage.ScopeType.UserGroup.rawValue:
                if let conversation = UserGroup(fromDictionary: dictionary) {
                    conversations.append(conversation)
                }
                
            default:
                continue
            }
        }
        
        conversations.sort {
            if let leftSent = $0.lastMessage?.sent, let rightSent = $1.lastMessage?.sent {
                return leftSent.compare(rightSent) == .orderedDescending
            } else {
                return false
            }
        }
        
        return conversations
    }
}
