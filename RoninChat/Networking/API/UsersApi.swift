import Foundation

open class UsersApi: ServerApi {
    
    override public init() {}
    
    public func getUserUrl(_ userId: String) -> String {
        return "\(apiUrl)\(usersPath)\(userId)"
    }
    
    public func getAllUsersUrl(_ networkId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(usersPath)"
    }
    
    
    // MARK: - API
    
    public func getUsers(networkId: String, completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        let url = getAllUsersUrl(networkId)
        
        RoninServerInterface.shared.getObjects(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackUsers(dictionaryArray)))
            }
        })
    }
    
    public func getUserById(userId: String, completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        let url = getUserUrl(userId)
        
        RoninServerInterface.shared.getObject(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionary): completion(.success(self.unpackUser(dictionary)))
            }
        })
    }
    
    
    // MARK: - Utility
    
    open func unpackUser(_ dictionary: [String: Any]) -> AnyObject? {
        return User(fromDictionary: dictionary)
    }
    
    open func unpackUsers(_ dictionaryArray: [[String: Any]]) -> [AnyObject] {
        var users = [User]()
        
        for dictionary in dictionaryArray {
            if let user = User(fromDictionary: dictionary) {
                users.append(user)
            }
        }
        
        users.sort {
            if $0.lastMessage != nil {
                if $1.lastMessage != nil {
                    return $0.lastMessage!.sent!.compare($1.lastMessage!.sent!) == .orderedDescending
                }
                return false
            } else if $1.lastMessage != nil {
                return false
            } else {
                return "\($0.lastName!)\($0.firstName!)" < "\($1.lastName!)\($1.firstName!)"
            }
        }
        
        return users
    }
}
