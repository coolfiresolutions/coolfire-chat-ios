import Foundation

open class AuthApi: ServerApi {
    
    override public init() {}
    
    public func getServerInfoUrl(_ endpointUrl: URL) -> URL {
        return endpointUrl.appendingPathComponent("/ronin/server/info")
    }
    
    public func getLogoutUrl() -> String {
        return "\(rootUrl)/ronin/\(logoutPath)"
    }
    
    
    // MARK: - API
    
    public func getServerInfo(url: URL, completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        let url = getServerInfoUrl(url)
        
        RoninServerInterface.shared.getData(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let data): completion(.success(self.unpackRoninServerConfig(data)))
            }
        })
    }
    
    public func login(url: String, parameters: [String: Any], headers: [String: String], completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        RoninServerInterface.shared.getData(url: authUrl, httpMethod: .post, parameters: parameters, headers: headers, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let data): completion(.success(self.unpackAuthToken(data)))
            }
        })
    }
    
    
    // MARK: - Utility
    
    open func unpackRoninServerConfig(_ data: Data) -> AnyObject? {
        return try? JSONDecoder().decode(RoninServerConfig.self, from: data)
    }
    
    open func unpackAuthToken(_ data: Data) -> AnyObject? {
        return try? JSONDecoder().decode(AuthToken.self, from: data)
    }
    
    open func unpackMfaResponse(_ data: Data) -> AnyObject? {
        return try? JSONDecoder().decode(AuthMfaResponse.self, from: data)
    }
}
