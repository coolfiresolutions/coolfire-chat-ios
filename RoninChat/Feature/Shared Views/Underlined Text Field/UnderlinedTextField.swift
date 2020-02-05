import UIKit

@IBDesignable
class UnderlinedTextField: UITextField {
    @IBInspectable var emptyColor: UIColor? = nil
    @IBInspectable var editingColor: UIColor? = nil
    @IBInspectable var completeColor: UIColor? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
    }
    
    override func draw(_ rect: CGRect) {
        updateView()
        super.draw(rect)
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        updateView()
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        updateView()
        return true
    }
    
    @objc func textFieldDidChange(textField: UITextField) {
        updateView()
    }
    
    func updateView() {
        if self.isFirstResponder, let color = editingColor {
            self.textColor = color
            addBottomBorder(with: color)
        } else if let text = self.text, !text.isEmpty, let color = completeColor {
            self.textColor = color
            addBottomBorder(with: color)
        } else if let color = emptyColor {
            addBottomBorder(with: color)
        }
        
        updatePlaceholderTextColor(with: emptyColor ?? .white)
    }
    
    func addBottomBorder(with color: UIColor) {
        self.removeBorders()
        self.addBottomBorderWith(color: color, width: 1.0)
    }
    
    func updatePlaceholderTextColor(with color: UIColor) {
        self.attributedPlaceholder = NSAttributedString(
            string: self.placeholder ?? "",
            attributes:[ NSAttributedString.Key.foregroundColor: color ]
        )
    }
}
