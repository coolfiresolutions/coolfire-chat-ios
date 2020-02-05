import UIKit

open class UserGroup: RoninObject, Messageable {
    public let entityType = RoninMessage.EntityType.UserGroup
    
    public var name: String?
    public var users: [User]!
    public var network: String?
    
    public var startDate: Date?
    public var stopDate: Date?
    
    // Messageable protocol
    public var lastMessage: RoninMessage?
    public var unreadMessageCount: Int = 0
    
    public class func toNewUserGroupDictionary(networkId: String, name: String, users: [User]) -> [String: Any] {
        var userIds = [String]()
        for user in users {
            userIds.append(user.id!)
        }
        
        return [
            "network": networkId,
            "name": name,
            "users": userIds
        ]
    }
    
    public override init?(fromDictionary dictionary: [String: Any]) {
        super.init(fromDictionary: dictionary)
        
        self.name = dictionary["name"] as! String?
        
        users = []
        if let usersArray = dictionary["users"] as? [[String : Any]] {
            for userDictionary in usersArray {
                if let user = User(fromDictionary: userDictionary) {
                    users.append(user)
                }
            }
        }
        
        self.network = dictionary["network"] as! String?
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let startDate: String = dictionary["startDate"] as? String {
            self.startDate = dateFormatter.date(from: startDate)
        }
        
        if let stopDate: String = dictionary["stopDate"] as? String {
            self.stopDate = dateFormatter.date(from: stopDate)
        }
        
        if let lastMessageDictionary = dictionary["lastMessage"] as? [String : Any] {
            self.lastMessage = RoninMessage(fromDictionary: lastMessageDictionary)
        }
        
        self.unreadMessageCount = dictionary["unreadMessages"] as? Int ?? 0
    }
    
    func updateBasedOnValues(_ userGroup: UserGroup) -> UserGroup {
        self.location = userGroup.location ?? self.location
        self.name = userGroup.name ?? self.name
        self.users = userGroup.users.isEmpty ? self.users : userGroup.users
        self.network = userGroup.network ?? self.network
        self.startDate = userGroup.startDate ?? self.startDate
        self.stopDate = userGroup.stopDate ?? self.stopDate
        self.lastMessage = userGroup.lastMessage ?? self.lastMessage
        
        return self
    }
}
