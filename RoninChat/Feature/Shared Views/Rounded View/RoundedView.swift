import UIKit

@IBDesignable
class RoundedView: UIView {
    @IBInspectable var isCircle: Bool = true
    @IBInspectable var cornerRadius: CGFloat = 0
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.cornerRadius = isCircle ? (self.bounds.size.width / 2.0) : cornerRadius
        self.layer.masksToBounds = true
    }
}
