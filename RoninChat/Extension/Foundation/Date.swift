import UIKit

extension Date {
    func getElapsedInterval() -> String {
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: Date())
        
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"
        let timeString = tf.string(from: self)
        
        if let year = interval.year, year > 0 {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            return df.string(from: self)
            
        } else if let month = interval.month, month > 0 {
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            return df.string(from: self)
            
        } else if let day = interval.day, day > 0 {
            let df = DateFormatter()
            df.dateFormat = "EEEE"
            return df.string(from: self)
            
        } else if let hour = interval.hour, hour > 0 {
            return "\(Calendar.current.isDateInYesterday(self) ? "Yesterday, " : "")\(timeString)"
            
        } else if let minute = interval.minute, minute > 0 {
            return timeString
            
        } else {
            return "just now"
        }
    }
    
    func getElapsedIntervalAndTime() -> String {
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: Date())
        
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"
        let timeString = tf.string(from: self)
        
        if let year = interval.year, year > 0 {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            return "\(df.string(from: self)), \(timeString)"
            
        } else if let month = interval.month, month > 0 {
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            return "\(df.string(from: self)), \(timeString)"
            
        } else if let day = interval.day, day > 0 {
            let df = DateFormatter()
            df.dateFormat = "EEEE"
            return "\(df.string(from: self)), \(timeString)"
            
        } else if let hour = interval.hour, hour > 0 {
            return "\(Calendar.current.isDateInYesterday(self) ? "Yesterday, " : "")\(timeString)"
            
        } else if let minute = interval.minute, minute > 0 {
            return timeString
            
        } else {
            return "just now"
        }
    }
}
