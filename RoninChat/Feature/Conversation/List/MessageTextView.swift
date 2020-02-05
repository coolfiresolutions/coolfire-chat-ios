import UIKit

@IBDesignable
class MessageTextView: UITextView {
    @IBInspectable var leftPadding: Int = 0 { didSet { updateEdgeInsets() }}
    @IBInspectable var topPadding: Int = 0 { didSet { updateEdgeInsets() }}
    @IBInspectable var rightPadding: Int = 0 { didSet { updateEdgeInsets() }}
    @IBInspectable var bottomPadding: Int = 0 { didSet { updateEdgeInsets() }}
    
    func updateEdgeInsets() {
        let defaultPadding = self.textContainer.lineFragmentPadding
        
        self.textContainerInset = UIEdgeInsets(
            top: topPadding.cgFloat,
            left: -defaultPadding + leftPadding.cgFloat,
            bottom: bottomPadding.cgFloat,
            right: -defaultPadding + leftPadding.cgFloat
        )
    }
}
