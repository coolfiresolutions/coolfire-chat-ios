import Foundation

extension String {    
    // Based on: https://stackoverflow.com/a/24408724
    var md5Hash: String {
        let trimmedString = lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
        let utf8String = trimmedString.cString(using: String.Encoding.utf8)!
        let stringLength = CC_LONG(trimmedString.lengthOfBytes(using: String.Encoding.utf8))
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)
        
        CC_MD5(utf8String, stringLength, result)
        
        var hash = ""
        
        for i in 0..<digestLength {
            hash += String(format: "%02x", result[i])
        }
        
        result.deallocate()
        
        return String(format: hash)
    }
}
