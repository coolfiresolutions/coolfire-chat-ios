import Foundation

extension Notification {
    public static var actionKey: String { get { return "action" }}
    public static var objectKey: String { get { return "object" }}
    
    public static var channelNotification: Name { get { return Name("SessionNotification") }}
    public static var textNotification: Name { get { return Name("TextNotification") }}
    public static var userGroupNotification: Name { get { return Name("UserGroupNotification") }}
}
