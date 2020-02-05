import UIKit

extension UIViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissKeyboard()
        super.touchesBegan(touches, with: event)
    }
    
    func getCustomAlertView() -> CustomAlertView {
        let customAlertView = UIStoryboard(
            name: CustomAlertView.storyboardName,
            bundle: nil
        ).instantiateViewController(withIdentifier: CustomAlertView.identifier) as! CustomAlertView
        
        customAlertView.providesPresentationContextTransitionStyle = true
        customAlertView.definesPresentationContext = true
        customAlertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        customAlertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        return customAlertView
    }
    
    @objc func displayAlert(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: handler)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: completion)
    }
}
