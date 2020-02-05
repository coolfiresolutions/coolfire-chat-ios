import UIKit
import WebKit

@IBDesignable
class LoaderView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var loadingLabel: UILabel!
    
    
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
        
        let htmlContent = "<img src=\"loader.gif\" style=\"margin: auto; height: 100% \" />"
        webView.loadHTMLString(htmlContent, baseURL: Bundle.main.bundleURL)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
}
