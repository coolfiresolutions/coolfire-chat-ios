import UIKit

extension UIView {
    func removeBorders() {
        self.layer.sublayers?.removeAll(where: { $0.name == "Border" })
        self.layer.layoutSublayers()
    }
    
    func addFourBordersWith(color: UIColor, width: CGFloat) {
        self.addTopBorderWith(color: color, width: width)
        self.addRightBorderWith(color: color, width: width)
        self.addBottomBorderWith(color: color, width: width)
        self.addLeftBorderWith(color: color, width: width)
    }
    
    func addTopBorderWith(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        border.name = "Border"
        self.layer.addSublayer(border)
    }
    
    func addRightBorderWith(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        border.name = "Border"
        self.layer.addSublayer(border)
    }
    
    func addBottomBorderWith(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        border.name = "Border"
        self.layer.addSublayer(border)
    }
    
    func addLeftBorderWith(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        border.name = "Border"
        self.layer.addSublayer(border)
    }
    
    func addMiddleBorderWith(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width / 2, y: 0, width: width, height: self.frame.size.height)
        border.name = "Border"
        self.layer.addSublayer(border)
    }
}
