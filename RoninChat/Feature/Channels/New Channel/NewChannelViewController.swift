import UIKit

class NewChannelViewController: UIViewController {
    public static let segueIdentifier: String = "showNewChannelViewController"
    public static let unwindSegueIdentifier: String = "unwindFromNewChannelViewController"
    
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var nameTextField: UnderlinedTextField!
    @IBOutlet var descriptionTextField: UnderlinedTextField!
    
    var channel: Channel?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ConversationViewController.segueIdentifier,
            let viewController = segue.destination as? ConversationViewController {
            
                viewController.conversation = channel
            
        }
    }
    
    @IBAction func confirmButtonTouchUpInside(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        
        self.activityIndicator.startAnimating()
        self.confirmButton.isHidden = true
        
        Ronin.shared.createChannel(name: name, description: (descriptionTextField.text ?? ""), completion: { channel in
            self.activityIndicator.stopAnimating()
            self.confirmButton.isHidden = false
            
            if let channel = channel {
                self.channel = channel
                self.performSegue(withIdentifier: ConversationViewController.segueIdentifier, sender: nil)
            } else {
                self.displayAlert(title: nil, message: "Error creating a new Channel, please try again")
            }
        })
    }
}


// MARK: UITextFieldDelegate

extension NewChannelViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            _ = descriptionTextField.becomeFirstResponder()
        } else {
            self.dismissKeyboard()
        }
        
        return true
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UnderlinedTextField) {
        guard let nameText = nameTextField.text, let descriptionText = descriptionTextField.text else { return }
        
        confirmButton.isEnabled = (!nameText.isEmpty && !descriptionText.isEmpty)
    }
}
