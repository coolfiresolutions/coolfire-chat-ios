import UIKit

class LoginViewController: UIViewController {
    public static let unwindSegueIdentifier: String = "unwindToLoginViewController"
    
    @IBOutlet var instanceTextField: UnderlinedTextField!
    @IBOutlet var usernameTextField: UnderlinedTextField!
    @IBOutlet var passwordTextField: UnderlinedTextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    @IBAction func unwindToLoginViewController(sender: UIStoryboardSegue) {}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func signInButtonOnTouchUpInside(_ sender: UIButton) {
        login()
    }
    
    func getUrlFromInstanceTextField() -> URL? {
        guard let text = instanceTextField.text, !text.isEmpty else { return nil }
        return URL(string: !text.contains("https://") ? "https://" + text : text)
    }
    
    @objc override func displayAlert(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil, completion: (() -> Void)? = nil) {
        self.signInButton.isHidden = false
        self.activityIndicatorView.isHidden = true
        
        super.displayAlert(title: title, message: message, handler: handler, completion: completion)
    }
    
    
    // MARK: Login Call Chain
    
    func login() {
        guard let url = getUrlFromInstanceTextField() else { return }
        
        signInButton.isHidden = true
        activityIndicatorView.isHidden = false
        
        Ronin.shared.config.url = url.absoluteString
        Ronin.shared.getInfo(completion: getInfoCompletionHandler)
    }
    
    func getInfoCompletionHandler(completed: Bool) {
        guard
            let username = usernameTextField.text,
            let password = passwordTextField.text
        else {
            return
        }
        
        if completed {
            Ronin.shared.login(username, password, completion: getAuthTokenCompletionHandler)
        } else {
            resetLoginChain()
            displayAlert(title: "Invalid URL", message: "Error reaching instanceURL, please make sure it's entered correctly")
        }
    }
    
    func getAuthTokenCompletionHandler(authToken: AuthToken?) {
        if let token = authToken {
            Ronin.shared.getAuthUserById(userId: token.userId, completion: getUserCompletionHandler)
        } else {
            resetLoginChain()
            displayAlert(title: "Invalid Login", message: "Please verify your username and password and try again")
        }
    }
    
    func getUserCompletionHandler(user: User?) {
        if user != nil {
            Ronin.shared.getNetwork(completion: getNetworkCompletionHandler)
        } else {
            resetLoginChain()
            displayAlert(title: "User not found", message: "Please ensure the user is created and try again")
        }
    }
    
    func getNetworkCompletionHandler(network: Network?) {
        if network != nil, let id = network?.id {
            Ronin.shared.getUsers(networkId: id, completion: { _ in })
            self.performSegue(withIdentifier: TabBarController.segueIdentifer, sender: nil)
        } else {
            resetLoginChain()
            displayAlert(title: "Network not found", message: "Please ensure the network is created and try again")
        }
        
        self.signInButton.isHidden = false
        self.activityIndicatorView.isHidden = true
    }
    
    func resetLoginChain() {
        Ronin.reset()
        self.signInButton.isHidden = false
        self.activityIndicatorView.isHidden = true
    }
}


// MARK: UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            _ = self.usernameTextField.becomeFirstResponder()
        case 1:
            _ = self.passwordTextField.becomeFirstResponder()
        case 2:
            self.dismissKeyboard()
            self.login()
        default:
            print("Unknown text field in LoginViewController")
        }
        
        return true
    }
}
