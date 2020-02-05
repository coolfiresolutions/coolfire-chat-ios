import UIKit

fileprivate var url: String?
fileprivate(set) var rootUrl: String {
    get {
        if url == nil || url!.isEmpty {
            fatalError("rootURL is not set")
        }
        
        return url!
    }
    set {
        url = newValue
    }
}

public let authPath = "/ronin/oauth2/token"
public let apiPath = "/ronin/api/v1/"
public var authUrl: String { get { return rootUrl + authPath }}
public var apiUrl: String { get { return rootUrl + apiPath }}

class AppConfig {
    private let id: String? = ""
    private let secret: String? = ""
    
    var clientId: String {
       get {
            if id == nil || id!.isEmpty {
                fatalError("clientId is not set")
            }
            
            return id!
        }
    }
    
    var clientSecret: String {
       get {
            if secret == nil || secret!.isEmpty {
                fatalError("clientSecret is not set")
            }
            
            return secret!
        }
    }
    
    var url: String = "" {
        didSet {
            rootUrl = url
        }
    }
    var authToken: AuthToken!
}
