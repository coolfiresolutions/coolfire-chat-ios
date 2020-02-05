import UIKit

public class KeyboardLayoutConstraint: NSLayoutConstraint {
    
    @IBInspectable var inTabViewController: Bool = false
    
    private var offset : CGFloat = 0
    private var keyboardVisibleHeight : CGFloat = 0
    
    
    @available(tvOS, unavailable)
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        offset = constant
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(KeyboardLayoutConstraint.keyboardWillShowNotification),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(KeyboardLayoutConstraint.keyboardWillHideNotification),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Notification
    
    @objc func keyboardWillShowNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let frame = frameValue.cgRectValue
                let bottomSafeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
                keyboardVisibleHeight = frame.size.height - bottomSafeAreaInset - (inTabViewController ? 49.0 : 0.0)
            }
            
            self.updateConstant()
            
            switch (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
                    userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber) {
                case let (.some(duration), .some(curve)):
                    let options = UIView.AnimationOptions(rawValue: curve.uintValue)
                    
                    UIView.animate(
                        withDuration: TimeInterval(duration.doubleValue),
                        delay: 0,
                        options: options,
                        animations: {
                            UIApplication.shared.keyWindow?.layoutIfNeeded()
                            return
                    }, completion: nil)
                default:
                    break
            }
        }
    }
    
    @objc func keyboardWillHideNotification(_ notification: NSNotification) {
        keyboardVisibleHeight = 0
        self.updateConstant()
        
        if let userInfo = notification.userInfo {
            
            switch (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
                    userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber) {
                
                case let (.some(duration), .some(curve)):
                    let options = UIView.AnimationOptions(rawValue: curve.uintValue)
                    
                    UIView.animate(
                        withDuration: TimeInterval(duration.doubleValue),
                        delay: 0,
                        options: options,
                        animations: {
                            UIApplication.shared.keyWindow?.layoutIfNeeded()
                            return
                    }, completion: nil)
                default:
                    break
            }
        }
    }
    
    func updateConstant() {
        self.constant = offset + keyboardVisibleHeight
    }
}
