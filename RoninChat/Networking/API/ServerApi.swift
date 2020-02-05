import Foundation

open class ServerApi {
    public static let userTextMessageNotification = Notification.Name("UserTextMessageNotification")
    
    public var conversationsPath: String = "userprofile/allConversations"
    public var filesPath: String = "files/"
    public var logoutPath: String = "logout"
    public var networksPath: String = "networks/"
    public var sessionsPath: String = "sessions/"
    public var userGroupsPath: String = "userGroups/"
    public var usersPath: String = "users/"
    public var userProfilePath: String = "userprofile/"
    
    public init() {}
}
