import AlamofireImage
import UIKit

fileprivate enum GravatarDefaultImage: String {
    case notFound = "404"
    case mysteryMan = "mm"
    case identicon = "identicon"
    case monster = "monsterid"
    case wavatar = "wavatar"
    case retro = "retro"
    case roboHash = "robohash"
    case blank = "blank"
}

fileprivate let gravatarBaseUrlString = "https://secure.gravatar.com/avatar/"

@IBDesignable
class AvatarView: UIView {
    @IBOutlet var view: UIStackView!
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    @IBInspectable var labelFontSize: Int = 0
    @IBInspectable var circular: Bool = true
    
    var user: User?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.label.font = UIFont(
            name: "Raleway-Medium",
            size: labelFontSize == 0 ? self.view.bounds.size.width / 2.0 : labelFontSize.cgFloat
        )
        self.layer.cornerRadius = circular ? (self.bounds.size.width / 2.0) : 0.0
        self.layer.masksToBounds = true
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
        view = (loadViewFromNib() as! UIStackView)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIStackView
        
        return view
    }
    
    func set(user: String) {
        self.label.text = user
    }
    
    func set(user: User) {
        self.user = user
        self.label.text = String(user.firstName?.first ?? " ").uppercased()
        
        if let email = user.email, let url = URL(string: "\(gravatarBaseUrlString)\(email.md5Hash)?d=blank") {
            self.imageView.af_setImage(withURL: url, placeholderImage: nil)
        }
    }
}
