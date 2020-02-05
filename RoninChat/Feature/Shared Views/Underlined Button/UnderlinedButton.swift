import UIKit

@IBDesignable
class UnderlinedButton: UIButton {
    @IBInspectable var underlined: Bool = true {
        didSet {
            guard underlined, let text = self.titleLabel?.text else { return }
            
            let attributedString = NSMutableAttributedString(string: text)
            
            attributedString.addAttribute(
                NSAttributedString.Key.underlineStyle,
                value: NSUnderlineStyle.single.rawValue,
                range: NSRange(location: 0, length: text.count)
            )
            
            self.setAttributedTitle(attributedString, for: .normal)
        }
    }
}
