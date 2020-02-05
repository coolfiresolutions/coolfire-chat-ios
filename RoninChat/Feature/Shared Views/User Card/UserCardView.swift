import UIKit

@objc
public protocol UserCardViewDelegate: NSObjectProtocol {
    @objc(touchUpInside)
    optional func buttonTouchUpInside()
}

@IBDesignable
class UserCardView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var onlineStatusView: RoundedView!
    @IBOutlet var onlineStatusLabelLeadingConstraintToOnlineStatusView: NSLayoutConstraint!
    @IBOutlet var onlineStatusLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var button: OutlinedButton!
    
    @IBOutlet open weak var delegate: UserCardViewDelegate?
    
    // MARK: Interface Builder Functions
    
    override func draw(_ rect: CGRect) {
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
}


// MARK: OutlinedButtonDelegate

extension UserCardView: OutlinedButtonDelegate {
    func touchUpInside() {
        if let function = delegate?.buttonTouchUpInside {
            function()
        }
    }
}
