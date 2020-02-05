import UIKit

class Headers {
    public static let contentType: String = "content-type"
    public static let deviceId: String = "device-id"
    public static let deviceType: String = "device-type"
    public static let deviceOs: String = "device-os"
    public static let devicePlatform: String = "device-platform"
    public static let devicePushToken: String = "push-token"
    public static let appId: String = "app-id"
    public static let deviceName: String = "device-name"
    
    class var `default`: [String : String] {
        return [
            deviceId: UIDevice.current.identifierForVendor!.uuidString.lowercased(),
            deviceType: UIDevice.current.model,
            deviceOs: UIDevice.current.systemVersion,
            devicePlatform: UIDevice.current.systemName,
            appId: Bundle.main.bundleIdentifier!,
            deviceName: UIDevice.current.name.replacingOccurrences(of: "'", with: "")
        ]
    }
}
