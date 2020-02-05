import UIKit

@IBDesignable
class SearchBarTextField: UITextField {
    @IBInspectable var placeHolderBorderColor: UIColor? = nil
    @IBInspectable var borderColor: UIColor? = nil
    @IBInspectable var leftPadding: CGFloat = 0 {
        didSet {
            leftViewMode = leftPadding == 0 ? .never : .always
        }
    }
    @IBInspectable var rightPadding: CGFloat = 0 {
        didSet {
            rightViewMode = rightPadding == 0 ? .never : .always
        }
    }
    @IBInspectable var placeholderTextColor: UIColor? = nil {
        didSet {
            self.attributedPlaceholder = NSAttributedString(
                string: self.placeholder ?? "Search",
                attributes:[ NSAttributedString.Key.foregroundColor: placeholderTextColor ?? .white ]
            )
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        updateView()
        self.leftView = UIView(frame: self.leftViewRect(forBounds: rect))
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var leftViewRect = super.leftViewRect(forBounds: bounds)
        leftViewRect.origin.x += leftPadding
        return leftViewRect
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateClearButton()
    }
    
    @objc func textFieldDidChange(textField: UITextField) {
        updateView()
    }
    
    func updateView() {
        if let text = self.text, !text.isEmpty, let color = borderColor {
            addBorder(with: color)
        } else if let color = placeHolderBorderColor {
            addBorder(with: color)
        }
    }
    
    func addBorder(with color: UIColor) {
        self.removeBorders()
        self.addFourBordersWith(color: color, width: 1.0)
    }
    
    func updateClearButton() {
        for view in subviews {
            if let button = view as? UIButton {
                // Adjust from default padding set by base UITextField
                button.frame.origin.x += 8.0
                button.frame.origin.x -= rightPadding
                button.setImage(#imageLiteral(resourceName: "ic_clear.pdf"), for: .normal)
                button.tintColor = .white
            }
        }
    }
}
