import Foundation

open class MessagesApi: ServerApi {
    
    override public init() {}
    
    public func getSessionMessagesUrl(_ networkId: String, _ sessionId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(userProfilePath)\(sessionsPath)\(sessionId)/messages"
    }
    
    public func getUserMessagesUrl(_ networkId: String, _ userId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(userProfilePath)\(usersPath)\(userId)/messages"
    }
    
    public func getUserGroupMessagesUrl(_ networkId: String, _ userGroupId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(userProfilePath)\(userGroupsPath)\(userGroupId)/messages"
    }
    
    
    // MARK: - API
    
    public func getSessionMessages(networkId: String, sessionId: String, completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        let url = getSessionMessagesUrl(networkId, sessionId)
        
        RoninServerInterface.shared.getObjects(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackMessages(dictionaryArray)))
            }
        })
    }
    
    public func getUserMessages(networkId: String, userId: String, completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        let url = getUserMessagesUrl(networkId, userId)
        
        RoninServerInterface.shared.getObjects(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackMessages(dictionaryArray)))
            }
        })
    }
    
    public func getUserGroupMessages(networkId: String, userGroupId: String, completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        let url = getUserGroupMessagesUrl(networkId, userGroupId)
        
        RoninServerInterface.shared.getObjects(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackMessages(dictionaryArray)))
            }
        })
    }
    
    
    // MARK: - Utility
    
    open func unpackMessages(_ dictionaryArray: [[String: Any]]) -> [AnyObject] {
        var messages = [RoninMessage]()
        
        for dictionary in dictionaryArray {
            if let message = RoninMessage(fromDictionary: dictionary) {
                messages.append(message)
            }
        }
        
        return messages
    }
}
