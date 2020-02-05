import UIKit

protocol CustomAlertViewDelegate: class {
    func customAlertDidLoad(_ customAlertView: CustomAlertView)
    func leftActionTapped()
    func rightActionTapped()
}

extension CustomAlertViewDelegate {
    func customAlertDidLoad(_ customAlertView: CustomAlertView) {
        //Do UI updates here, if needed
    }
}

class CustomAlertView: UIViewController {
    public static let storyboardName: String = "CustomAlert"
    public static let identifier: String = "CustomAlertView"
    
    @IBOutlet var alertView: RoundedView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    
    var delegate: CustomAlertViewDelegate?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector (handleTap))
        self.view.addGestureRecognizer(gesture)
        
        delegate?.customAlertDidLoad(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        animateView()
    }
    
    func animateView() {
        alertView.alpha = 0
        self.alertView.frame.origin.y = self.alertView.frame.origin.y + 50
        
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.alertView.alpha = 1.0
            self.alertView.frame.origin.y = self.alertView.frame.origin.y - 50
        })
    }
    
    @objc func handleTap() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func leftActionTapped(_ sender: UIButton) {
        delegate?.leftActionTapped()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func rightActionTapped(_ sender: UIButton) {
        delegate?.rightActionTapped()
        self.dismiss(animated: true, completion: nil)
    }
}
