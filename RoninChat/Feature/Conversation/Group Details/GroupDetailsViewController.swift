import UIKit

protocol GroupDetailsViewControllerDelegate {
    func groupDetailsDidSave(title: String)
}

class GroupDetailsViewController: UIViewController, UITextFieldDelegate {
    public static let segueIdentifier: String = "showGroupDetailsViewController"
    public static let unwindSegueIdentifier: String = "unwindFromGroupDetailsViewController"
    
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var titleEditIconImageView: UIImageView!
    @IBOutlet var tableView: UITableView!
    
    var delegate: GroupDetailsViewControllerDelegate?
    
    var group: UserGroup?
    var users: [User] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.text = group?.name
        users = group?.users ?? []
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard let text = sender.text else { return }
        
        titleEditIconImageView.tintColor = (text != (group?.name ?? "")) ? #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1) : #colorLiteral(red: 0.5292221904, green: 0.5332366228, blue: 0.5414741635, alpha: 1)
        saveButton.isHidden = !(text != (group?.name ?? ""))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    @IBAction func saveButtonTouchUpInside(_ sender: UIButton) {
        guard let groupId = group?.id, let title = titleTextField.text else { return }
        
        self.saveButton.isHidden = true
        self.activityIndicator.startAnimating()
        
        Ronin.shared.patchGroupDetails(groupId, with: title, completion: { userGroup in
            self.saveButton.isHidden = false
            self.activityIndicator.stopAnimating()
            
            if userGroup != nil {
                self.delegate?.groupDetailsDidSave(title: title)
                self.performSegue(withIdentifier: GroupDetailsViewController.unwindSegueIdentifier, sender: nil)
            } else {
                self.displayAlert(title: "Error saving", message: "There was an error saving Group details, please try again")
            }
        })
    }
}


// MARK: UITableViewDataSource, UITableViewDelegate

extension GroupDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PeopleTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! PeopleTableViewCell
        
        cell.avatarView.set(user: user)
        cell.nameLabel.text = user.fullName
        cell.emailLabel?.text = user.email
        
        return cell
    }
}
