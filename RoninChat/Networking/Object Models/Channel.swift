import Foundation
import CoreLocation

open class Channel: RoninObject, Messageable, Searchable {
    public enum Status: String {
        case closed
        case open
        case inprogress
        case cancelled
    }
    
    public let entityType = RoninMessage.EntityType.Session
    
    public var typeId: String!
    public var image: String?
    public var name: String!
    public var channelDescription: String?
    public var status: Status!
    public var users: [User] = []
    
    public var messages: [Any]?
    
    public var lastMessage: RoninMessage?
    public var unreadMessageCount = 0
    
    public var createdBy: String?
    public var modifiedBy: String?
    public var deletedBy: String?
    
    public var createdAt: Date?
    public var modifiedAt: Date?
    public var deletedAt: Date?
    
    // Searchable protocol
    public var searchable: String! {
        get {
            return self.name
        }
    }
    
    public class func toNewChannelDictionary(networkId: String, name: String, description: String) -> [String: Any] {
        return [
            "network" : networkId,
            "name" : name,
            "description" : description,
            "status": "open"
        ]
    }
    
    public override init?(fromDictionary dictionary: Dictionary<String, Any>) {
        super.init(fromDictionary: dictionary)
        
        self.typeId = dictionary["sessType"] as? String
        self.name = dictionary["name"] as? String
        self.channelDescription = dictionary["description"] as? String
        
        if let statusString = dictionary["status"] as? String {
            self.status = Status.init(rawValue: statusString)
        } else {
            self.status = .open
        }
        
        self.unreadMessageCount = dictionary["unreadMessages"] as? Int ?? 0
        
        if let lastMessageDictionary = dictionary["lastMessage"] as? Dictionary<String, Any> {
            self.lastMessage = RoninMessage(fromDictionary: lastMessageDictionary)
        }
        
        self.createdBy = dictionary["createdBy"] as? String
        self.modifiedBy = dictionary["modifiedBy"] as? String
        self.deletedBy = dictionary["deletedBy"] as? String
        
        if let audit = dictionary["audit"] as? [String: Any] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            if let dateString: String = audit["createdAt"] as? String {
                self.createdAt = dateFormatter.date(from: dateString)
            }
            
            if let dateString: String = audit["modifiedAt"] as? String {
                self.modifiedAt = dateFormatter.date(from: dateString)
            }
            
            if let dateString: String = audit["deletedAt"] as? String {
                self.deletedAt = dateFormatter.date(from: dateString)
            }
        }
    }
    
    public func updateBasedOnValues(_ channel: Channel) -> Channel {
        self.createdAt = channel.createdAt ?? self.createdAt
        self.createdBy = channel.createdBy ?? self.createdBy
        self.deletedAt = channel.deletedAt ?? self.deletedAt
        self.deletedBy = channel.deletedBy ?? self.deletedBy
        self.image = channel.image ?? self.image
        self.lastMessage = channel.lastMessage ?? self.lastMessage
        self.location = channel.location ?? self.location
        self.messages = channel.messages ?? self.messages
        self.modifiedAt = channel.modifiedAt ?? self.modifiedAt
        self.modifiedBy = channel.modifiedBy ?? self.modifiedBy
        self.name = channel.name ?? self.name
        self.channelDescription = channel.channelDescription ?? self.channelDescription
        self.status = channel.status ?? self.status
        self.typeId = channel.typeId ?? self.typeId
        self.users = channel.users
        
        return self
    }
    
    public func contains(_ user: User) -> Bool {
        return self.users.contains(where: { $0.id == user.id })
    }
    
    public func add(_ user: User) {
        if !self.contains(user) {
            self.users.append(user)
        }
    }
}
