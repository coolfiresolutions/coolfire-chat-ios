import Alamofire
import Foundation

public enum RoninServerResult<T> {
    case failure(Error)
    case success(T)
}

public typealias RequestCompletion<T> = (T) -> Void
public typealias ServerRequest<T, U> = (T, @escaping RequestCompletion<U>) -> Void


open class RoninServerInterface {
    public private(set) var oAuthHandler: OAuth2Handler?
    public private(set) var session: Session = Alamofire.Session.default
    public var debugMode: DebugMode = .error
    
    public var defaultHeaders: HTTPHeaders {
        return [
            "Content-type": "application/json",
            "Authorization": "Bearer " + (oAuthHandler?.accessToken ?? "")
        ]
    }
    
    public static let shared : RoninServerInterface = {
        let instance = RoninServerInterface()
        return instance
    }()
    
    public init() {}
    
    public func setupAuthHandler(_ authHandler: OAuth2Handler, _ delegate: OAuth2HandlerDelegate) {
        self.oAuthHandler = authHandler
        self.oAuthHandler?.delegate = delegate
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = self.defaultHeaders.dictionary
        
        self.session = Session(configuration: configuration, interceptor: Interceptor(adapter: authHandler, retrier: authHandler))
    }
    
    public func refreshAccessToken(_ accessToken: String) {}
    
    public func getUrlRequest(url: String, headers: [String: String]? = nil, httpMethod: HTTPMethod, parameters: [String: Any]) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: url)!)
        urlRequest.allHTTPHeaderFields = headers ?? defaultHeaders.dictionary
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: httpMethod == .patch ? [parameters] : parameters , options: [])
        return urlRequest
    }
    
    public func getUrlRequest(url: String, headers: [String: String]? = nil, httpMethod: HTTPMethod, parameters: [[String: Any]]) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: url)!)
        urlRequest.allHTTPHeaderFields = headers ?? defaultHeaders.dictionary
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: parameters , options: [])
        return urlRequest
    }
    
    public func getData(url: URL, completion: @escaping RequestCompletion<RoninServerResult<Data>>) {
        self.session.request(url).responseData { response in
            switch response.result {
            case .success:
                guard let responseData = response.data else {
                    completion(.failure(NSError(domain: "Unable to obtain data from response", code: 1, userInfo: nil)))
                    return
                }
                
                completion(.success(responseData))
                
            case .failure(let error):
                self.printMessage(error, type: .error)
                completion(.failure(error))
            }
        }
    }
    
    public func getData(url: String, httpMethod: HTTPMethod, parameters: [String: Any], headers: [String: String], completion: @escaping RequestCompletion<RoninServerResult<Data>>) {
        self.session.request(url, method: httpMethod, parameters: parameters, headers: HTTPHeaders(headers)).validate(statusCode: 200..<300).responseJSON { response in
            switch response.result {
            case .success:
                guard let responseData = response.data else {
                    completion(.failure(NSError(domain: "Unable to obtain data from response", code: 1, userInfo: nil)))
                    return
                }
                
                completion(.success(responseData))
                
            case .failure(let error):
                print(error)
                guard let responseData = response.data else {
                    completion(.failure(error))
                    return
                }
                
                let mfa = self.unpackMfaResponse(responseData) as? AuthMfaResponse
                let domain = mfa?.description ?? mfa?.error ?? "An unknown error occured"
                completion(.failure(NSError(domain: domain, code: 1, userInfo: nil)))
            }
        }
    }
    
    public func getObject(url: String, completion: @escaping RequestCompletion<RoninServerResult<[String: Any]>>)  {
        self.session.request(url, headers: defaultHeaders).validate().responseJSON { response in
            switch response.result {
            case .success(let data):
                guard let responseDictionary = data as? [String: Any] else {
                    completion(.failure(NSError(domain: "Result not in dictionary format", code: 1, userInfo: nil)))
                    return
                }
                
                completion(.success(responseDictionary))
                
            case .failure(let error):
                self.printMessage(error, type: .error)
                completion(.failure(error))
            }
        }
    }
    
    public func getObject(with urlRequest: URLRequest, completion: @escaping RequestCompletion<RoninServerResult<[String: Any]>>) {
        self.session.request(urlRequest).validate(statusCode: 200..<300).responseJSON { response in
            switch response.result {
            case .success(let data):
                guard let responseDictionary = data as? [String: Any] else {
                    completion(.failure(NSError(domain: "Result not in dictionary format", code: 1, userInfo: nil)))
                    return
                }
                
                completion(.success(responseDictionary))
                
            case .failure(let error):
                self.printMessage(error, type: .error)
                completion(.failure(error))
            }
        }
    }
    
    public func getObjects(url: String, completion: @escaping RequestCompletion<RoninServerResult<[[String: Any]]>>)  {
        self.session.request(url, headers: defaultHeaders).validate().responseJSON { response in
            switch response.result {
            case .success(let data):
                guard let responseDictionary = data as? [[String: Any]] else {
                    completion(.failure(NSError(domain: "Result not in dictionary array format", code: 1, userInfo: nil)))
                    return
                }
                completion(.success(responseDictionary))
                
            case .failure(let error):
                self.printMessage(error, type: .error)
                completion(.failure(error))
            }
        }
    }
    
    public func perform(url: String, httpMethod: HTTPMethod, parameters: [String: Any], headers: [String: String]? = nil, completion: @escaping (Bool) -> Void) {
        self.session.request(url, method: httpMethod, parameters: parameters, encoding: URLEncoding.default, headers: HTTPHeaders(headers ?? defaultHeaders.dictionary)).responseData { response in
            switch response.result {
            case .success: completion(true)
            case .failure(let error):
                self.printMessage(error, type: .error)
                completion(false)
            }
        }
    }
    
    public func perform(with urlRequest: URLRequest, completion: @escaping (Bool) -> Void) {
        self.session.request(urlRequest).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success: completion(true)
            case .failure(let error):
                self.printMessage(error, type: .error)
                completion(false)
            }
        }
    }
    
    public func upload(url: String,
                       headers: [String: String],
                       data: Data,
                       fileName: String,
                       mimeType: String,
                       parameters: [String : Any]?,
                       onProgress: ((Progress) -> Void)? = nil,
                       onCompletion: ((Data?) -> Void)? = nil,
                       onError: ((Error?) -> Void)? = nil
    ) {
        AF.upload(
            multipartFormData: { multipartFormData in
                if let params = parameters {
                    for (key, value) in params {
                        multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                    }
                }
                multipartFormData.append(data, withName: "file", fileName: fileName, mimeType: mimeType)
            },
            with: self.getUrlRequest(url: url, httpMethod: .post, parameters: parameters ?? [:])
        )
        .uploadProgress(queue: .main, closure: { progress in
            onProgress?(progress)
        })
        .response { result in
            if let err = result.error {
                onError?(err)
                return
            }
        
            onCompletion?(result.data)
        }
    }
    
    open func unpackMfaResponse(_ data: Data) -> AnyObject? {
        return try? JSONDecoder().decode(AuthMfaResponse.self, from: data)
    }
    
    private func printMessage(_ message: Any, type: DebugMode) {
        switch self.debugMode {
        case .silent:
            return
        case .error:
            if type == .error { print(message) }
        case .verbose:
            print(message)
        }
    }
}
