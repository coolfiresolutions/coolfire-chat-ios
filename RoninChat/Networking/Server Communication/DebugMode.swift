import Foundation

public enum DebugMode {
    static let `default`: DebugMode = .error
    
    case silent
    case error
    case verbose
}
