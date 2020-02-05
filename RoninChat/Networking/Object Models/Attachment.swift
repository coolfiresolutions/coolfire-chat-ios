import UIKit

open class Attachment: NSObject, Codable {
    public var id: String?
    public var filename: String?
    public var length: Int?
    public var uploadDate: Date?
    public var md5: String?
    public var contentType: String?
    public var url: URL?
    
    public var data: Data? = nil
    
    public enum CodingKeys: String, CodingKey {
        case id
        case filename
        case length
        case uploadDate
        case md5
        case contentType
    }
    
    public enum Content: String {
        case image
        case video
        case document = "application"
        case unsupported
        
        public static func get(type: String) -> Content {
            switch type {
            case let x where x.contains(image.rawValue):
                return .image
            case let x where x.contains(video.rawValue):
                return .video
            case let x where x.contains(document.rawValue):
                return .document
            default:
                return .unsupported
            }
        }
    }
    
    public init(filename: String, contentType: String, data: Data) {
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }
    
    public init?(fromDictionary dictionary: [String: Any]) {
        guard let identifier = dictionary["id"] as? String else {
            print("\(#function) returning nil: id required")
            return nil
        }
        
        self.id = identifier
        self.filename = dictionary["filename"] as? String
        self.length = dictionary["length"] as? Int
        
        if let dateString: String = dictionary["uploadDate"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            self.uploadDate = dateFormatter.date(from: dateString)
        }
        
        self.md5 = dictionary["md5"] as? String
        self.contentType = dictionary["contentType"] as? String
        
        if let urlString = dictionary["url"] as? String {
            self.url = URL(string: urlString)
        }
    }
    
}
