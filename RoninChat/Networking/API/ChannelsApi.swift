import Foundation

open class ChannelsApi: ServerApi {
    public lazy var channelsUrl = apiUrl + sessionsPath
    
    override public init() {}
    
    public func getChannelUrl(_ channelId: String) -> String {
        return "\(channelsUrl)\(channelId)"
    }
    
    public func getAllChannelsUrl(_ networkId: String) -> String {
        return "\(apiUrl)\(networksPath)\(networkId)/\(sessionsPath)withRecentActivity?status=open"
    }
    
    
    // MARK: - API
    
    public func getChannels(networkId: String, completion: @escaping RequestCompletion<RoninServerResult<[AnyObject]>>) {
        RoninServerInterface.shared.getObjects(url: getAllChannelsUrl(networkId), completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionaryArray): completion(.success(self.unpackChannels(dictionaryArray)))
            }
        })
    }
    
    public func createChannel(parameters: [String: Any], completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: channelsUrl, httpMethod: .post, parameters: parameters)
        
        RoninServerInterface.shared.getObject(with: urlRequest, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionary): completion(.success(self.unpackChannel(dictionary)))
            }
        })
    }
    
    public func patchChannel(_ channelId: String, parameters: [[String: Any]], completion: @escaping RequestCompletion<RoninServerResult<AnyObject?>>) {
        let url = getChannelUrl(channelId)
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: url, httpMethod: .patch, parameters: parameters)
        
        RoninServerInterface.shared.getObject(with: urlRequest, completion: { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let dictionary): completion(.success(self.unpackChannel(dictionary)))
            }
        })
    }
    
    public func deleteChannel(_ channelId: String, completion: @escaping (Bool) -> Void) {
        let urlRequest = RoninServerInterface.shared.getUrlRequest(url: getChannelUrl(channelId), httpMethod: .delete, parameters: [:])
        RoninServerInterface.shared.perform(with: urlRequest, completion: completion)
    }
    
    
    // MARK: - Utility
    
    open func unpackChannel(_ dictionary: [String: Any]) -> AnyObject? {
        return Channel(fromDictionary: dictionary)
    }
    
    open func unpackChannels(_ dictionaryArray: [[String: Any]]) -> [AnyObject] {
        var channels = [Channel]()
        
        for dictionary in dictionaryArray {
            if let object = Channel(fromDictionary: dictionary) {
                channels.append(object)
            }
        }
        
        channels.sort {
            guard
                let first = $0.lastMessage?.sent ?? $0.createdAt,
                let second = $1.lastMessage?.sent ?? $1.createdAt
            else {
                return false
            }
            
            return first.compare(second) == ComparisonResult.orderedDescending
        }
        
        return channels
    }
}
