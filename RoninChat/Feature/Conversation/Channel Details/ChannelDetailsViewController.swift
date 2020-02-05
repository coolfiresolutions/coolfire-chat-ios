import UIKit

protocol ChannelDetailsViewControllerDelegate {
    func channelDetailsDidSave(title: String, description: String)
}

class ChannelDetailsViewController: UIViewController, UITextFieldDelegate {
    public static let segueIdentifier: String = "showChannelDetailsViewController"
    public static let unwindSegueIdentifier: String = "unwindFromChannelDetailsViewController"
    
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var titleEditIconImageView: UIImageView!
    @IBOutlet var descriptionTextField: UITextField!
    @IBOutlet var descriptionEditIconImageView: UIImageView!
    
    var delegate: ChannelDetailsViewControllerDelegate?
    
    var channel: Channel?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.text = channel?.name
        descriptionTextField.text = channel?.channelDescription
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard let text = sender.text else { return }
        var isTitleEdited: Bool = false
        var isDescriptionEditied: Bool = false
        
        isTitleEdited = (text != (channel?.name ?? ""))
        titleEditIconImageView.tintColor = isTitleEdited ? #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1) : #colorLiteral(red: 0.5292221904, green: 0.5332366228, blue: 0.5414741635, alpha: 1)
        
        isDescriptionEditied = (text != (channel?.channelDescription ?? ""))
        descriptionEditIconImageView.tintColor = isDescriptionEditied ? #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1) : #colorLiteral(red: 0.5292221904, green: 0.5332366228, blue: 0.5414741635, alpha: 1)
        
        saveButton.isHidden = !(isTitleEdited || isDescriptionEditied)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    @IBAction func saveButtonTouchUpInside(_ sender: UIButton) {
        guard let channelId = channel?.id, let title = titleTextField.text, let description = descriptionTextField.text else { return }
        
        self.saveButton.isHidden = true
        self.activityIndicator.startAnimating()
        
        Ronin.shared.patchChannelDetails(channelId, with: title, and: description, completion: { channel in
            self.saveButton.isHidden = false
            self.activityIndicator.stopAnimating()
            
            if channel != nil {
                self.delegate?.channelDetailsDidSave(title: title, description: description)
                self.performSegue(withIdentifier: ChannelDetailsViewController.unwindSegueIdentifier, sender: nil)
            } else {
                self.displayAlert(title: "Error saving", message: "There was an error saving Channel details, please try again")
            }
        })
    }
}
