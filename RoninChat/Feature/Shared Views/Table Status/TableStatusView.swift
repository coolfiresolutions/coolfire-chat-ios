import UIKit

@IBDesignable
class TableStatusView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!
    @IBInspectable var image: UIImage? = nil
    @IBInspectable var labelText: String? = nil
    
    
    // MARK: Interface Builder Functions
    
    override func draw(_ rect: CGRect) {
        if let image = self.image {
            set(image: image)
        }
        if let text = self.labelText {
            set(labelText: text)
        }
        
        super.draw(rect)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
    
    func set(image: UIImage) {
        self.image = image
        self.imageView.image = image
    }
    
    func set(labelText: String) {
        self.labelText = labelText
        self.label.text = labelText
    }
}
