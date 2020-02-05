import UIKit

open class RoninServerConfig: NSObject, Codable {
    public var nodeENV: String?
    public var serverVersion: String?
    public var serverName: String?
    public var hostName: String?
    public var serverDescription: String?
    public var APIVersion: String?
    public var buildDate: String?
    public var uptime: Double?
    public var authStrategy: String?
    public var fileSizeLimit: String?
    public var info: RoninServerInfo?
}
