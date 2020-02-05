import UIKit
import CoreLocation

open class Network: RoninObject {
    public var name: String!
    public var textDescription: String?
    public var iconUrl: String?
    public var primaryColor = UIColor(named: "373c3e")
    public var isHidden: Bool = false
    public var isPrivate: Bool = false
    public var isFavorite: Bool = false
    
    public var createdBy: String?
    public var modifiedBy: String?
    public var deletedBy: String?
    
    public var users: [String] = []
    
    
    public init?(id: String, name: String) {
        super.init(fromDictionary: ["id" : id])
        
        self.id = id
        self.name = name
    }
    
    public override init?(fromDictionary dictionary: Dictionary<String, Any>) {
        super.init(fromDictionary: dictionary)
        
        self.name = dictionary["name"] as! String?
        self.textDescription = dictionary["description"] as? String
        self.isHidden = dictionary["isHidden"] as! Bool
        self.isHidden = dictionary["isPrivate"] as! Bool
        self.iconUrl = dictionary["iconUrl"] as? String
        
        if let color = dictionary["color"] as? String {
            self.primaryColor = UIColor(named: color)
        }
        
        self.users = dictionary["users"] as! [String]
    }
    
    public func toFavoriteDictionary() -> [String: Any] {
        return [
            "isFavorite": self.isFavorite,
            "muted": self.isHidden
        ]
    }
}
