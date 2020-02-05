import UIKit

@objc
public protocol OutlinedButtonDelegate: NSObjectProtocol {
    @objc(touchUpInside)
    optional func touchUpInside()
}

@IBDesignable
class OutlinedButton: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var label: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    @IBInspectable var viewBackgroundColor: UIColor? = nil
    @IBInspectable var borderColor: UIColor? = nil
    @IBInspectable var labelText: String? = nil
    @IBInspectable var labelTextColor: UIColor? = nil
    @IBInspectable var image: UIImage? = nil
    @IBInspectable var imageTint: UIColor? = nil
    
    @IBOutlet open weak var delegate: OutlinedButtonDelegate?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let color = viewBackgroundColor {
            view.backgroundColor = color
        }
        if let color = borderColor {
            removeBorders()
            addFourBordersWith(color: color, width: 1.0)
        }
        if let text = labelText {
            label.text = text
        }
        if let color = labelTextColor {
            self.label.textColor = color
        }
        if let image = self.image {
            iconImageView.image = image
        }
        if let color = imageTint {
            iconImageView.tintColor = color
        }
        
        label.font = UIFont(name: "Open Sans", size: self.label.bounds.size.height / 2.0)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }
    
    func setup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    @IBAction func touchUpInside(_ sender: UIButton) {
        if let function = delegate?.touchUpInside {
            function()
        }
    }
}

