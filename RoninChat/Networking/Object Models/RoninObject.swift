import CoreLocation
import UIKit

public protocol Searchable {
    var searchable: String! { get }
}

open class RoninObject: NSObject {
    public var id: String?
    public var location: CLLocation?
    
    public init?(fromDictionary dictionary: Dictionary<String, Any>) {
        self.id = dictionary["id"] as? String
        
        if let loc = dictionary["loc"] as? [String: Any],
            let lat = loc["lat"] as? CLLocationDegrees,
            let lon = loc["lon"] as? CLLocationDegrees{
            
            self.location = CLLocation(latitude:lat, longitude:lon)
        }
    }
}
