import Alamofire
import UIKit

public protocol OAuth2HandlerDelegate {
    func didRefreshAuthToken(_ authToken: AuthToken)
}

public class OAuth2Handler: RequestAdapter, RequestRetrier {
    private typealias RefreshCompletion = (_ succeeded: Bool, _ userId: String?, _ tokenType: String?, _ accessToken: String?, _ refreshToken: String?, _ expiresIn: Int?) -> Void
    
    private(set) lazy var sessionManager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = RoninServerInterface.shared.defaultHeaders.dictionary
        
        return Session(configuration: configuration)
    }()
    
    private let lock = NSLock()
    
    private var baseURLString: String
    
    private var clientID: String
    private var clientSecret: String
    
    private(set) var userId: String
    private(set) var tokenType: String
    private(set) var accessToken: String
    private(set) var refreshToken: String
    private(set) var expiresIn: Int
    
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []
    
    public var debugMode: DebugMode = .error
    public var delegate: OAuth2HandlerDelegate?
    
    
    public init(baseURLString: String, clientID: String, clientSecret: String, userId: String, tokenType: String, accessToken: String, refreshToken: String, expiresIn: Int) {
        self.baseURLString = baseURLString
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.userId = userId
        self.tokenType = tokenType
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
    
    
    // MARK: - RequestAdapter
    
    public func adapt(_ urlRequest: URLRequest, for session: Alamofire.Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix(baseURLString) {
            var urlRequest = urlRequest
            urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            completion(.success(urlRequest))
        }
        
        completion(.success(urlRequest))
    }
    
    
    // MARK: - RequestRetrier
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        lock.lock() ; defer { lock.unlock() }
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] succeeded, userId, tokenType, accessToken, refreshToken, expiresIn in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                    
                    if let userId = userId,
                        let tokenType = tokenType,
                        let accessToken = accessToken,
                        let refreshToken = refreshToken,
                        let expiresIn = expiresIn {
                        
                        strongSelf.userId = userId
                        strongSelf.tokenType = tokenType
                        strongSelf.accessToken = accessToken
                        strongSelf.refreshToken = refreshToken
                        strongSelf.expiresIn = expiresIn
                        
                        let authToken = AuthToken(userId: userId, tokenType: tokenType, accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
                        strongSelf.delegate?.didRefreshAuthToken(authToken)
                    }
                    
                    strongSelf.requestsToRetry.forEach { $0(.retry) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }
    
    
    // MARK: - Private - Refresh Tokens
    
    private func refreshTokens(completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        let urlString = "\(baseURLString)\(authPath)/"
        
        let parameters: [String: Any] = [
            "grant_type": "refresh_token",
            "client_id": clientID,
            "client_secret": clientSecret,
            "access_token": accessToken,
            "refresh_token": refreshToken,
        ]
        
        sessionManager.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                
                switch response.result {
                    
                case .success(let data):
                    if
                        let json = data as? [String: Any],
                        let userId = json[AuthToken.CodingKeys.userId.rawValue] as? String,
                        let tokenType = json[AuthToken.CodingKeys.tokenType.rawValue] as? String,
                        let accessToken = json[AuthToken.CodingKeys.accessToken.rawValue] as? String,
                        let refreshToken = json[AuthToken.CodingKeys.refreshToken.rawValue] as? String,
                        let expiresIn = json[AuthToken.CodingKeys.expiresIn.rawValue] as? Int
                    {
                        completion(true, userId, tokenType, accessToken, refreshToken, expiresIn)
                    }
                case .failure(let error):
                    if self?.debugMode == .error { print(error) }
                    completion(false, nil, nil, nil, nil, nil)
                }
                
                strongSelf.isRefreshing = false
        }
    }
}
