import Foundation
import UIKit

open class FilesApi: ServerApi {
    public lazy var filesUrl = apiUrl + filesPath
    
    // MARK: - API
    
    override public init() {}
    
    public func getFileDownloadUrl(fileID: String) -> URL? {
        if let url = URL(string: fileID), UIApplication.shared.canOpenURL(url) {
            return url
        }
        
        return URL(string: "\(apiUrl)\(filesPath)\(fileID)/download")
    }
    
    public func upload(data: Data,
                       fileName: String,
                       mimeType: String,
                       parameters: [String : Any]?,
                       onProgress: ((Progress) -> Void)? = nil,
                       onCompletion: ((Data?) -> Void)? = nil,
                       onError: ((Error?) -> Void)? = nil) {
        let headers = [
            "authorization" : "bearer " + (RoninServerInterface.shared.oAuthHandler?.accessToken)!,
            "content-type": "multipart/form-data"
        ]
        
        RoninServerInterface.shared.upload(
            url: filesUrl,
            headers: headers,
            data: data,
            fileName: fileName,
            mimeType: mimeType,
            parameters: parameters,
            onProgress: onProgress,
            onCompletion: onCompletion,
            onError: onError
        )
    }
}
