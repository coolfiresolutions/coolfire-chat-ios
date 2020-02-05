import UIKit

public protocol Messageable : class {
    var id: String? { get set }
    var entityType: RoninMessage.EntityType { get }
    var unreadMessageCount: Int { get set }
    var lastMessage: RoninMessage? { get set }
}

open class RoninMessage: NSObject {
    public enum EntityType: String {
        case Event = "event"
        case Network = "network"
        case Session = "session"
        case User = "user"
        case UserGroup = "userGroup"
        case Text = "text"
        case Other
    }
    
    public enum Action: String {
        case Create = "create"
        case Delete = "delete"
        case Update = "update"
        case RemoveUser = "removeUser"
        case Other
    }
    
    public enum ActorType: String {
        case ApplicationLink = "applicationLink"
        case System = "system"
        case Thing = "thing"
        case User = "user"
        case Other
    }
    
    public enum ScopeType: String {
        case Network = "network"
        case Session = "session"
        case User = "user"
        case UserGroup = "userGroup"
        case Other
    }
    
    public class ActorId {
        var id: String?
        var type: ActorType
        
        public init(id: String?, type: ActorType) {
            self.id = id
            self.type = type
        }
        
        public func toDictionary() -> [String: Any] {
            var dictionary = [String: Any]()
            
            if let id = self.id {
                dictionary["id"] = id
            }
            dictionary["type"] = self.type.rawValue
            
            return dictionary
        }
    }
    
    public class ScopeId {
        var id: String
        var type: ScopeType?
        
        public init(id: String, type: ScopeType?) {
            self.id = id
            self.type = type
        }
        
        public func toDictionary() -> [String: Any] {
            var dictionary = [String: Any]()
            
            dictionary["id"] = self.id
            dictionary["type"] = self.type != nil ? type!.rawValue : NSNull()
            
            return dictionary
        }
    }
    
    public var id: String!                 // unique message identifier
    public var actorId: ActorId!           // id (optional) and type of creator of message
    public var targets = [ScopeId]()       // list of scopes the message is intended for
    public var sent: Date!                 // when the message was sent
    
    public var type: EntityType!           // what kind of object this message relates to
    public var action: Action!             // what kind of change this message conveys
    public var data: [String: Any]?        // payload that depends on the action and type
    public var attachments: [Attachment]?
    
    public var userId: String? {
        get {
            return actorId.type == .User ? actorId.id : nil
        }
    }
    
    public var targetId: String? {
        get {
            return targets.count > 0 ? targets[0].id : nil
        }
    }
    
    public var targetType: ScopeType {
        get {
            return targets.count > 0 ? targets[0].type ?? .Other : .Other
        }
    }
    
    public var body: String? {
        get {
            if let dataDictionary = self.data {
                return dataDictionary["body"] as? String
            }
            else {
                return nil
            }
        }
        
        set (body) {
            if var dataDictionary = self.data {
                dataDictionary["body"] = body
            }
        }
    }
    
    public var messageDescription: String? {
        return ((self.body)?.isEmpty ?? true) ? (!(self.attachments?.isEmpty ?? true) ? "Attachment" : "") : self.body
    }
    
    public override init() { }
    
    public init?(fromDictionary dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String else {
            return nil
        }
        
        self.id = id
        
        if let actorDictionary = dictionary["actorId"] as? [String: Any] {
            self.actorId = ActorId(
                id: actorDictionary["id"] as? String,
                type: ActorType(rawValue: actorDictionary["type"] as? String ?? "Other") ?? .Other
            )
        }
        
        if let targets = dictionary["targets"] as? [[String : Any]] {
            for targetDictionary in targets {
                if let id = targetDictionary["id"] as? String {
                    self.targets.append(ScopeId(id: id, type: ScopeType(rawValue: targetDictionary["type"] as? String ?? "Other")))
                }
            }
        }
        
        if let dateString: String = dictionary["sent"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            self.sent = dateFormatter.date(from: dateString)
        }
        
        if let entityTypeString = dictionary["type"] as? String {
            self.type = EntityType.init(rawValue: entityTypeString)
        }
        else {
            self.type = EntityType.Other
        }
        
        if let actionString = dictionary["action"] as? String {
            self.action = Action.init(rawValue: actionString)
        }
        else {
            self.action = Action.Other
        }
        
        if let data = dictionary["data"] as? [String: Any] {
            self.data = data
            
            if let attachments = data["attachments"] as? [[String: Any]] {
                self.attachments = [Attachment]()
                
                for item in attachments  {
                    if let attachment = Attachment(fromDictionary: item) {
                        self.attachments?.append(attachment)
                    }
                }
            }
        }
        
    }
    
    public init(id: String, userId: String, targetId: String, targetType: ScopeType, sent: Date, type: EntityType, action: Action, data: [String: Any]) {
        self.id = id
        self.actorId = ActorId(id: userId, type: .User)
        self.targets = [ScopeId(id: targetId, type: targetType)]
        self.sent = sent
        
        self.type = type
        self.action = action
        self.data = data
    }
    
    public func toDictionary() -> [String: Any] {
        var dictionary = [String: Any]()
        
        dictionary["id"] = self.id
        dictionary["actorId"] = self.actorId.toDictionary()
        
        var targetsDictionary = [[String: Any]]()
        for target in targets {
            targetsDictionary.append(target.toDictionary())
        }
        dictionary["targets"] = targetsDictionary
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dictionary["sent"] = dateFormatter.string(from: self.sent)
        
        dictionary["type"] = self.type.rawValue
        dictionary["action"] = self.action.rawValue
        dictionary["data"] = self.data
        
        return dictionary
    }
}
