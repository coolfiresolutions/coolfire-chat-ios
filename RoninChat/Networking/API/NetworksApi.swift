import Foundation

open class NetworksApi: ServerApi {
    public lazy var allNetworksUrl: String = apiUrl + networksPath
    public lazy var allFavoriteNetworksUrl: String = apiUrl + userProfilePath + "networks?isFavorite=true"
    
    override public init() {}
    
    public func getNetworkFromPrefsUrl(_ networkId: String) -> String {
        return "\(apiUrl)\(usersPath)\(userProfilePath)network/\(networkId)"
    }
    
    
    // MARK: - API
    
    public func getNetworks(completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        RoninServerInterface.shared.getObjects(url: allNetworksUrl, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackNetworks(from: dictionaryArray)))
            }
        })
    }
    
    public func getFavoriteNetworks(completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        RoninServerInterface.shared.getObjects(url: allFavoriteNetworksUrl, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackNetworks(from: dictionaryArray)))
            }
        })
    }
    
    public func postFavoriteNetwork(networkId: String, parameters: [String: Any], completion: @escaping (Bool) -> Void) {
        let url = getNetworkFromPrefsUrl(networkId)
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: url, httpMethod: .post, parameters: parameters)
        
        RoninServerInterface.shared.perform(with: urlRequest, completion: completion)
    }
    
    public func getFirstNetwork(completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        let url = "\(allNetworksUrl)?skip=0&limit=1"
        RoninServerInterface.shared.getObjects(url: url, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackNetworks(from: dictionaryArray)[0]))
            }
        })
    }
    
    
    // MARK: - Utility
    
    open func unpackNetwork(_ dictionary: [String: Any]) -> AnyObject? {
        return Network(fromDictionary: dictionary)
    }
    
    open func unpackNetworks(from dictionaryArray: [[String: Any]]) -> [AnyObject] {
        var networks = [Network]()
        
        for dictionary in dictionaryArray {
            if let network = Network(fromDictionary: dictionary) {
                networks.append(network)
            }
        }
        
        networks.sort {
            return $0.name.lowercased() < $1.name.lowercased()
        }
        
        return networks
    }
}
