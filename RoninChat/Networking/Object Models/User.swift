import Foundation

open class User: RoninObject, Messageable {
    public static var onlineTimeIntervalSinceNow = -600.0
    public let entityType = RoninMessage.EntityType.User
    
    public var userName: String!
    public var firstName: String?
    public var lastName: String?
    public var type: String?
    public var creationDate: Date?
    public var status: Int?
    
    public var lastPresentDate: Date?
    
    public var conversations: [Messageable]?
    public var extensions: Array<Any>?
    
    public var email: String?
    
    
    // Messageable protocol
    public var lastMessage: RoninMessage?
    public var unreadMessageCount: Int = 0
    
    public var initials: String {
        get {
            let first = self.firstName ?? "-"
            let last = self.lastName ?? "-"
            return (!first.isEmpty ? String(describing: first.first!).uppercased() : first) + (!last.isEmpty ? String(describing: last.first!).uppercased() : last)
        }
    }
    
    public var fullName: String {
        get {
            let first = self.firstName ?? ""
            let last = self.lastName ?? ""
            return "\(first) \(last)"
        }
    }
    
    public var isOnline: Bool {
        if let last = lastPresentDate {
            let interval = last.timeIntervalSinceNow
            if (interval > User.onlineTimeIntervalSinceNow) {
                return true
            }
        }
        
        return false
    }
    
    public override init?(fromDictionary dictionary: Dictionary<String, Any>) {
        super.init(fromDictionary: dictionary)
        
        self.userName = dictionary["userName"] as? String
        self.firstName = dictionary["firstName"] as? String
        self.lastName = dictionary["lastName"] as? String
        self.email = dictionary["email"] as? String
        self.status = dictionary["status"] as? Int
        self.type = dictionary["type"] as? String
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let dateString: String = dictionary["creationDate"] as? String {
            self.creationDate = dateFormatter.date(from: dateString)
        }
        
        if let dateString: String = dictionary["lastPresentDate"] as? String {
            self.lastPresentDate = dateFormatter.date(from: dateString)
        }
        
        if let lastMessageDictionary = dictionary["lastMessage"] as? [String : Any] {
            self.lastMessage = RoninMessage(fromDictionary: lastMessageDictionary)
        }
        
        self.unreadMessageCount = dictionary["unreadMessages"] as? Int ?? 0
    }
}


// MARK: - Searchable

extension User: Searchable {
    public var searchable: String! {
        get {
            return self.fullName + self.userName
        }
    }
}

extension User: Comparable {
    public static func < (lhs: User, rhs: User) -> Bool {
        return lhs.fullName > rhs.fullName
    }
}
