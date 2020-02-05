import Foundation
import SocketIO

public protocol SocketIOHandlerDelegate {
    func didReceiveMessage(_ messageDictionary: [String: Any])
    func didReceiveSocketIoStatusUpdate(_ status: SocketIOStatus?)
}

open class SocketIOHandler {
    public let socketIoNsp: String = "/"
    public let socketIoPath: String = "/ronin/socket.io"
    
    public var clientId: String?
    public var clientSecret: String?
    
    public var socketIoClient: SocketIOClient?
    public var socketManager: SocketManager?
    public var delegate: SocketIOHandlerDelegate?
    
    public var debugMode: DebugMode = .error
    
    
    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    public func refreshAccessToken(_ accessToken: String, _ userId: String?) {
        if let socketIoClient = socketIoClient, socketIoClient.status != .notConnected {
            if socketIoClient.status != .disconnected {
                socketIoClient.disconnect()
            }
            
            if userId != nil {
                setupSocketIo(userId!)
            }
        }
    }
    
    public func setupSocketIo(_ userId: String) {
        setupSocketIo(userId, forcePolling: true, log: true)
    }
    
    public func setupSocketIo(_ userId: String, forcePolling: Bool, log: Bool) {
        guard let accessToken = RoninServerInterface.shared.oAuthHandler?.accessToken,
            let clientId = self.clientId,
            let clientSecret = self.clientSecret else {
                printMessage("SocketIO: No access token, clientId, or clientSecret availble for socket connection", type: .error)
                return
        }
        
        let extraHeaders: [String: String] = ["Authorization": "Bearer \(accessToken)"]
        self.socketManager = SocketManager(socketURL: URL(string: rootUrl)!, config: [.log(log),
                                                                                      .forcePolling(forcePolling),
                                                                                      .extraHeaders(extraHeaders),
                                                                                      .path(socketIoPath),
                                                                                      .connectParams(["token": accessToken,
                                                                                                      "clientId": clientId,
                                                                                                      "clientSecret": clientSecret])
        ])
        
        self.socketIoClient = self.socketManager!.socket(forNamespace: socketIoNsp)
        
        self.socketIoClient!.on("connect") { data, ack in
            self.printMessage("SocketIO: connected", type: .verbose)
            
            self.socketIoClient?.emitWithAck("join", userId).timingOut(after: 60) {data in
                self.delegate?.didReceiveSocketIoStatusUpdate(self.socketIoClient?.status)
            }
        }
        
        self.socketIoClient!.on("message") { data, ack in
            guard let delegate = self.delegate else {
                self.printMessage("SocketIO: New message ignored. No delegate specified to receive SocketIO messages.", type: .error)
                return
            }
            
            for message in data {
                guard let messageDictionary = message as? [String: Any] else {
                    self.printMessage("SocketIO: New message skipped. Not in dictionary format.", type: .error)
                    return
                }
                
                delegate.didReceiveMessage(messageDictionary)
            }
        }
        
        self.socketIoClient!.on(SocketClientEvent.statusChange.rawValue) { data, ack in
            self.printMessage("SocketIO: status change", type: .verbose)
            self.delegate?.didReceiveSocketIoStatusUpdate(self.socketIoClient?.status)
        }
        
        self.socketIoClient!.on(SocketClientEvent.error.rawValue) { data, ack in
            self.printMessage("SocketIO: error", type: .error)
            self.printMessage(data, type: .error)
        }
        
        self.socketIoClient!.on(SocketClientEvent.disconnect.rawValue) { data, ack in
            self.printMessage("SocketIO: disconnect", type: .verbose)
            self.printMessage(data, type: .verbose)
        }
        
        self.socketIoClient!.on(SocketClientEvent.reconnectAttempt.rawValue) { data, ack in
            self.printMessage("SocketIO: reconnect attempt", type: .verbose)
        }
        
        self.socketIoClient!.on(SocketClientEvent.reconnect.rawValue) { data, ack in
            self.printMessage("SocketIO: reconnect", type: .verbose)
        }
        
        
        self.socketIoClient!.connect()
    }
    
    public func emit(_ event: String, body: [String: Any], completion: @escaping () -> Void) {
        guard socketIoClient?.status == .connected else {
            completion()
            return
        }
        
        printMessage(body)
        
        self.socketIoClient?.emitWithAck(event, body).timingOut(after: 60) { data in
            self.printMessage(data, type: .verbose)
            completion()
        }
    }
    
    public func emit(_ event: String, body: String, completion: @escaping () -> Void) {
        guard socketIoClient?.status == .connected else {
            completion()
            return
        }
        
        self.printMessage(body)
        
        self.socketIoClient?.emitWithAck(event, body).timingOut(after: 60) { data in
            self.printMessage(data, type: .verbose)
            completion()
        }
    }
    
    public func emit(_ event: String, body: [String: Any]) {
        guard socketIoClient?.status == .connected else {
            return
        }
        
        self.printMessage(body)
        
        self.socketIoClient?.emitWithAck(event, body).timingOut(after: 60) { data in
            self.printMessage(data, type: .verbose)
        }
    }
    
    public func emit(_ event: String, body: String) {
        guard socketIoClient?.status == .connected else {
            return
        }
        
        self.printMessage(body)
        
        self.socketIoClient?.emitWithAck(event, body).timingOut(after: 60) { data in
            self.printMessage(data, type: .verbose)
        }
    }
    
    public func emit(_ event: String, _ argument1: String, _ argument2: String) {
        guard socketIoClient?.status == .connected else {
            return
        }
        
        self.printMessage(argument1, argument2)
        
        self.socketIoClient?.emitWithAck(event, argument1, argument2).timingOut(after: 60) { data in
            self.printMessage(data, type: .verbose)
        }
    }
    
    public func emit(_ event: String, body: [String: Any], completion: @escaping (RoninMessage?) -> Void) {
        guard socketIoClient?.status == .connected else {
            completion(nil)
            return
        }
        
        self.socketIoClient?.emitWithAck(event, body).timingOut(after: 60) { data in
            if let dictionary = data[1] as? [String: Any] {
                completion(RoninMessage(fromDictionary: dictionary))
            }
        }
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
    
    private func printMessage(_ body: SocketData...) {
        var theJSONData: Data?
        do {
            theJSONData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            self.printMessage("Error serializing Socket Data = \(body)", type: .error)
            return
        }
        
        let theJSONText = NSString(data: theJSONData!, encoding: String.Encoding.ascii.rawValue)
        self.printMessage("JSON string = \(theJSONText!)", type: .verbose)
    }
}
