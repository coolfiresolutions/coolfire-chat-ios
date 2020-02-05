import Alamofire
import Foundation
import SocketIO

class Ronin {
    private(set) static var shared = Ronin()
    
    class func reset() {
        shared = Ronin()
    }
    
    private(set) var config = AppConfig()
    private(set) var serverInfo: RoninServerConfig?
    private(set) var authUser: User!
    private(set) var network: Network?
    private(set) var users: [User] = []
    
    private var authApi = AuthApi()
    private var channelsApi = ChannelsApi()
    private var conversationsApi = ConversationsApi()
    private var filesApi = FilesApi()
    private var messagesApi = MessagesApi()
    private var networksApi = NetworksApi()
    private var usersApi = UsersApi()
    
    private(set) var roninServerInterface = RoninServerInterface.shared
    private(set) lazy var socket = SocketIOHandler(clientId: config.clientId, clientSecret: config.clientSecret)
    
    public var debugMode: DebugMode = DebugMode.default
    
    init() {
        self.socket.delegate = self
        self.set(debugMode: self.debugMode)
    }
    
    func signOut() {
        socket.socketIoClient?.disconnect()
        authUser = nil
        network = nil
    }
    
    func reconnectIfNeeded() {
        if socket.socketIoClient?.status != .connected, let authUserId = authUser?.id! {
            socket.setupSocketIo(authUserId, forcePolling: false, log: (self.debugMode == .error || self.debugMode == .verbose))
        }
    }
    
    func disconnetSocket() {
        if let currentNetwork = network, let id = currentNetwork.id {
            self.socket.emit("leave network", body: id)
        }
        socket.socketIoClient?.disconnect()
    }
    
    
    // MARK: Server Info
    
    func getInfo(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: config.url) else { return completion(false) }
        
        authApi.getServerInfo(url: url, completion: { result in
            switch result {
            case .failure(let error):
                self.printMessage("Error getting Server Info: \(error.localizedDescription)", type: .error)
                completion(false)
            case .success(let unpackedRoninServerConfig):
                if let roninServerConfig = unpackedRoninServerConfig as? RoninServerConfig {
                    self.serverInfo = roninServerConfig
                    completion(true)
                }
            }
        })
    }
    
    
    // MARK: Authentication
    
    func login(_ username: String, _ password: String, completion: @escaping (AuthToken?) -> Void) {
        let parameters = [
            "grant_type": "password",
            "username": username,
            "password": password,
            "client_id": config.clientId,
            "client_secret": config.clientSecret
        ]
        
        authApi.login(url: config.url, parameters: parameters, headers: Headers.default, completion: { result in
            switch result {
            case .failure(_): completion(nil)
            case .success(let unpackedAuthToken):
                if let authToken = unpackedAuthToken as? AuthToken {
                    self.config.authToken = authToken
                    self.setupAuthHandler(authToken)
                }
                
                completion(unpackedAuthToken as? AuthToken)
            }
        })
    }
    
    
    // MARK: Conversations
    
    func getConversations(completion: @escaping ([Messageable]?) -> Void) {
        guard let networkId = network?.id else {  return completion(nil) }
        
        conversationsApi.getConversations(networkId: networkId, completion: { result in
            var conversations: [Messageable]?
            
            switch result {
            case .failure(let error): self.printMessage("Get Conversations in Network failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedConversations): conversations = unpackedConversations as? [Messageable]
            }
            
            completion(conversations)
        })
    }
    
    func removeUserConversation(_ userId: String, completion: @escaping (Bool) -> Void) {
        guard let networkId = Ronin.shared.network?.id else { return completion(false) }
        conversationsApi.removeUserConversation(networkId: networkId, userId: userId, completion: completion)
    }
    
    func createUserGroup(users: [User], completion: @escaping (UserGroup?) -> Void) {
        guard let networkId = Ronin.shared.network?.id else { return completion(nil) }
        
        var name = ""
        for user in users {
            name.append(name.isEmpty ? "" : ", ")
            name.append(user.fullName)
        }
        
        let parameters = UserGroup.toNewUserGroupDictionary(networkId: networkId, name: name, users: (users))
        
        conversationsApi.createUserGroup(parameters: parameters, completion: { result in
            var userGroup: UserGroup?
            
            switch result {
            case .failure(let error): self.printMessage("Create UserGroup failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedUserGroup): userGroup = unpackedUserGroup as? UserGroup
            }
            
            completion(userGroup)
        })
    }
    
    func removeUserGroup(_ groupId: String, completion: @escaping (Bool) -> Void) {
        guard let networkId = Ronin.shared.network?.id else { return completion(false) }
        conversationsApi.removeUserGroupConversation(networkId: networkId, groupId: groupId, parameters: ["isHidden" : true], completion: completion)
    }
    
    func patchGroupDetails(_ userGroupId: String, with name: String, completion: @escaping (UserGroup?) -> Void) {
        let parameters: [String : Any] = [
            "op": "replace",
            "path" : "/name",
            "value": name
        ]
        
        conversationsApi.patchUserGroup(userGroupId, parameters: parameters, completion: { result in
            var userGroup: UserGroup?
            
            switch result {
            case .failure(let error): self.printMessage("Patch UserGroup failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedUserGroup): userGroup = unpackedUserGroup as? UserGroup
            }
            
            completion(userGroup)
        })
    }
    
    
    // MARK: Files
    
    func getFileDownloadUrl(fileID: String) -> URL? {
        let url = filesApi.getFileDownloadUrl(fileID: fileID)
        
        return url
    }
    
    
    // MARK: Messages
    
    func getMessages(for conversation: Messageable, completion: @escaping ([RoninMessage]?) -> Void) {
        switch conversation.entityType {
        case .User:
            guard let user = conversation as? User else { return completion([]) }
            
            getUserMessages(for: user, completion: completion)
        case .UserGroup:
            guard let userGroup = conversation as? UserGroup else { return completion([]) }
            
            getUserGroupMessages(for: userGroup, completion: completion)
        case .Session:
            guard let channel = conversation as? Channel else { return completion([]) }
            
            getChannelMessages(for: channel, completion: completion)
        default:
            printMessage("Unhandled Entity Type in getMessages() in Ronin instance", type: .verbose)
            completion([])
        }
    }
    
    func getUserMessages(for user: User, completion: @escaping ([RoninMessage]?) -> Void) {
        guard let networkId = self.network?.id, let userId = user.id else { return completion(nil) }
        
        messagesApi.getUserMessages(networkId: networkId, userId: userId, completion: { result in
            var messages: [RoninMessage]?
            
            switch result {
            case .failure(let error): self.printMessage("Get User Messages failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedMessages): messages = unpackedMessages as? [RoninMessage]
            }
            
            completion(messages)
        })
    }
    
    func getUserGroupMessages(for userGroup: UserGroup, completion: @escaping ([RoninMessage]?) -> Void) {
        guard let networkId = self.network?.id, let userGroupId = userGroup.id else { return completion(nil) }
        
        messagesApi.getUserGroupMessages(networkId: networkId, userGroupId: userGroupId, completion: { result in
            var messages: [RoninMessage]?
            
            switch result {
            case .failure(let error): self.printMessage("Get User Group Messages failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedMessages): messages = unpackedMessages as? [RoninMessage]
            }
            
            completion(messages)
        })
    }
    
    func getChannelMessages(for channel: Channel, completion: @escaping ([RoninMessage]?) -> Void) {
        guard let networkId = self.network?.id, let channelId = channel.id else { return completion(nil) }
        
        messagesApi.getSessionMessages(networkId: networkId, sessionId: channelId, completion: { result in
            var messages: [RoninMessage]?
            
            switch result {
            case .failure(let error): self.printMessage("Get Channel Messages failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedMessages): messages = unpackedMessages as? [RoninMessage]
            }
            
            completion(messages)
        })
    }
    
    func sendMessage(to conversationId: String, body: String, attachment: Attachment?, scopeType: RoninMessage.ScopeType, completion: @escaping (RoninMessage?) -> Void) {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let dispatchGroup = DispatchGroup()
        var returnedAttachments = [Attachment]()
        
        
        if let attachment = attachment, let data = attachment.data, let mimeType = attachment.contentType {
            dispatchGroup.enter()
            
            filesApi.upload(data: data,
                            fileName: attachment.filename ?? UUID().uuidString,
                            mimeType: mimeType,
                            parameters: nil,
                            onCompletion:
            { data in
                if let attachmentData = data {
                    do {
                        print(attachmentData)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        decoder.dateDecodingStrategy = .formatted(dateFormatter)
                        
                        let decodedAttachment = try decoder.decode(Attachment.self, from: attachmentData)
                        returnedAttachments.append(decodedAttachment)
                    } catch {
                        self.printMessage(error, type: .error)
                    }
                }
                dispatchGroup.leave()
                
            }, onError: { error in
                if let error = error {
                    self.printMessage(error, type: .error)
                }
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            let roninMessage = RoninMessage()
            roninMessage.id = UUID().uuidString.lowercased()
            roninMessage.actorId = RoninMessage.ActorId(id: self.authUser!.id, type: .User)
            roninMessage.targets.append(
                RoninMessage.ScopeId(
                    id: conversationId,
                    type: scopeType
                )
            )
            
            roninMessage.sent = Date()
            roninMessage.type = RoninMessage.EntityType.Text
            roninMessage.action = RoninMessage.Action.Create
            
            var data = [String: Any]()
            data["body"] = body
            data["network"] = self.network!.id
            do {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                encoder.dateEncodingStrategy = .formatted(dateFormatter)
                
                let attachData = try encoder.encode(returnedAttachments)
                let attachArray = try JSONSerialization.jsonObject(with: attachData, options: .allowFragments) as! [[String: Any]]
                data["attachments"] = attachArray
                roninMessage.attachments = returnedAttachments
            } catch {
                self.printMessage(error, type: .error)
            }
            roninMessage.data = data
            
            self.socket.emit("message", body: roninMessage.toDictionary(), completion: { returnedRoninMessage in
                guard returnedRoninMessage != nil else { return completion(nil) }
                
                roninMessage.id = returnedRoninMessage?.id ?? roninMessage.id
                
                NotificationCenter.default.post(
                    name: Notification.textNotification,
                    object: [Notification.objectKey : roninMessage]
                )
                
                completion(roninMessage)
            })
        }
    }
    
    
    // MARK: Networks
    
    func getNetwork(completion: @escaping (Network?) -> Void) {
        networksApi.getFirstNetwork(completion: { result in
            switch result {
            case .failure(let error): self.printMessage("Get First Network failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedNetwork): self.network = unpackedNetwork as? Network
            }
            
            completion(self.network)
        })
    }
    
    func setupAuthHandler(_ authToken: AuthToken) {
        let authHandler = OAuth2Handler(baseURLString: rootUrl,
                                        clientID: config.clientId,
                                        clientSecret: config.clientSecret,
                                        userId: authToken.userId,
                                        tokenType: authToken.tokenType,
                                        accessToken: authToken.accessToken,
                                        refreshToken: authToken.refreshToken,
                                        expiresIn: authToken.expiresIn)
        
        roninServerInterface.setupAuthHandler(authHandler, self)
        set(debugMode: self.debugMode)
    }
    
    
    // MARK: Sessions(Channels)
    
    func getChannels(completion: @escaping ([Channel]?) -> Void) {
        guard let networkId = network?.id else {  return completion(nil) }
        
        channelsApi.getChannels(networkId: networkId, completion: { result in
            var channels: [Channel]?
            
            switch result {
            case .failure(let error): self.printMessage("Get Channels failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedChannels): channels = unpackedChannels as? [Channel]
            }
            
            completion(channels)
        })
    }
    
    func createChannel(name: String, description: String, completion: @escaping (Channel?) -> Void) {
        guard let networkId = network?.id else { return completion(nil) }
        
        let parameters = Channel.toNewChannelDictionary(networkId: networkId, name: name, description: description)
        
        channelsApi.createChannel(parameters: parameters, completion: { result in
            var channel: Channel?
            
            switch result {
            case .failure(let error): self.printMessage("Create Channel failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedChannel): channel = unpackedChannel as? Channel
            }
            
            completion(channel)
        })
    }
    
    func patchChannelDetails(_ channelId: String, with name: String, and description: String, completion: @escaping (Channel?) -> Void) {
        let parameters: [[String : Any]] = [
            [
                "op": "replace",
                "path" : "/name",
                "value": name
            ],
            [
                "op": "replace",
                "path" : "/description",
                "value": description
            ]
        ]
        
        channelsApi.patchChannel(channelId, parameters: parameters, completion: { result in
            var channel: Channel?
            
            switch result {
            case .failure(let error): self.printMessage("Patch Channel failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedChannel): channel = unpackedChannel as? Channel
            }
            
            completion(channel)
        })
    }
    
    func deleteChannel(_ channelId: String, completion: @escaping (Bool) -> Void) {
        channelsApi.deleteChannel(channelId, completion: completion)
    }
    
    
    // MARK: Users
    
    func getAuthUserById(userId: String, completion: @escaping (User?) -> Void) {
        usersApi.getUserById(userId: userId, completion: { result in
            var user: User?
            
            switch result {
            case .failure(let error): self.printMessage("Get Auth User by ID failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedUser): user = unpackedUser as? User
            }
            
            if user != nil, let id = user?.id {
                self.authUser = user
                self.socket.setupSocketIo(id, forcePolling: false, log: (self.debugMode == .error || self.debugMode == .verbose))
            }
            
            completion(user)
        })
    }
    
    func getUsers(networkId: String, completion: @escaping ([User]) -> Void) {
        usersApi.getUsers(networkId: networkId, completion: { result in
            switch result {
            case .failure(let error): self.printMessage("Get all Users in Network failure: \(error.localizedDescription)", type: .error)
            case .success(let unpackedUsers):
                self.users = (unpackedUsers as? [User] ?? []).sorted()
                completion(self.users)
            }
        })
    }
    
    
    // MARK: Utility Functions
    
    func set(debugMode: DebugMode) {
        self.debugMode = debugMode
        self.roninServerInterface.debugMode = debugMode
        self.roninServerInterface.oAuthHandler?.debugMode = debugMode
        self.socket.debugMode = debugMode
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


// MARK: SocketIOHandlerDelegate

extension Ronin: SocketIOHandlerDelegate {
    func didReceiveMessage(_ messageDictionary: [String : Any]) {
        guard
            let actionString = messageDictionary["action"] as? String,
            let action = RoninMessage.Action(rawValue: actionString),
            let entityTypeString = messageDictionary["type"] as? String,
            let messageType = RoninMessage.EntityType(rawValue: entityTypeString),
            let messageData = messageDictionary["data"] as? [String: Any],
            let id = messageData["id"] as? String
        else {
            printMessage("SocketIOHandlerDelegate: New message skipped.", type: .verbose)
            return
        }
        
        switch messageType {
        case .Session:
            if action == .Create {
                self.socket.emit("join", body: id)
            }
            
            if let channel = Channel(fromDictionary: messageData) {
                NotificationCenter.default.post(
                    name: Notification.channelNotification,
                    object: [Notification.objectKey : channel, Notification.actionKey : action]
                )
            }
        case .UserGroup:
            if action == .Create {
                self.socket.emit("join", body: id)
            }
            
            if let userGroup = UserGroup(fromDictionary: messageData) {
                NotificationCenter.default.post(
                    name: Notification.userGroupNotification,
                    object: [Notification.objectKey : userGroup, Notification.actionKey : action]
                )
            }
        case .Text:
            if let roninMessage = RoninMessage(fromDictionary: messageDictionary) {
                NotificationCenter.default.post(
                    name: Notification.textNotification,
                    object: [Notification.objectKey : roninMessage]
                )
            }
        default:
            printMessage("Unhandled message type: \(messageType)", type: .verbose)
        }
    }
    
    func didReceiveSocketIoStatusUpdate(_ status: SocketIOStatus?) {
        if (status ?? SocketIOStatus.notConnected) == .connected {
            guard let networkId = self.network?.id, let authUserId = self.authUser.id else {
                return
            }
            
            printMessage("Emitting Join Network: \(networkId)", type: .verbose)
            self.socket.emit("join network", body: networkId)
            self.socket.emit("join", body: authUserId)
        }
        
        printMessage("Socket status changed -> \(status?.description ?? "")", type: .verbose)
    }
}


// MARK: OAuth2HandlerDelegate

extension Ronin: OAuth2HandlerDelegate {
    func didRefreshAuthToken(_ authToken: AuthToken) {
        socket.refreshAccessToken(authToken.accessToken, authUser?.id!)
    }
}
