import UIKit

class NewMessageViewController: UIViewController {
    public static let segueIdentifier: String = "showNewMessageViewController"
    public static let unwindSegueIdentifier: String = "unwindFromNewMessageViewController"
    
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var searchTextField: SearchBarTextField!
    @IBOutlet var searchBarTopConstraintToHeaderView: NSLayoutConstraint!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var tableView: UITableView!
    
    var users: [User] = []
    var selectedUsers: [User] = []
    lazy var filteredUsers: [User] = users
    var userGroup: UserGroup?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.users = Ronin.shared.users
        self.users.removeAll(where: { $0.id == Ronin.shared.authUser.id })
        searchBarTopConstraintToHeaderView.isActive = !selectedUsers.isEmpty
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ConversationViewController.segueIdentifier,
            let viewController = segue.destination as? ConversationViewController {
            
                if selectedUsers.count == 1 {
                    viewController.conversation = selectedUsers[0]
                } else {
                    userGroup?.users.removeAll(where: { $0.id == Ronin.shared.authUser.id })
                    viewController.conversation = userGroup
                }
            
        }
    }
    
    func reloadData() {
        filterUsers()
        confirmButton.isEnabled = !selectedUsers.isEmpty
        searchBarTopConstraintToHeaderView.isActive = !selectedUsers.isEmpty
        collectionView.reloadData()
        tableView.reloadData()
    }
    
    func filterUsers() {
        let text = searchTextField.text ?? ""
        
        self.filteredUsers = text.isEmpty ?
            users.difference(from: selectedUsers) :
            users.filter({
                $0.fullName.lowercased().contains(text.lowercased()) || $0.userName.lowercased().contains(text.lowercased())
            }).difference(from: selectedUsers)
        self.filteredUsers.sort()
        
        self.tableView.reloadData()
    }
    
    @IBAction func confirmButtonTouchUpInside(_ sender: UIButton) {
        if selectedUsers.count == 1 {
            self.performSegue(withIdentifier: ConversationViewController.segueIdentifier, sender: nil)
        } else {
            self.confirmButton.isHidden = true
            self.activityIndicator.startAnimating()
            
            Ronin.shared.createUserGroup(users: selectedUsers + [Ronin.shared.authUser], completion: { userGroup in
                self.confirmButton.isHidden = false
                self.activityIndicator.stopAnimating()
                
                if let userGroup = userGroup {
                    self.userGroup = userGroup
                    self.performSegue(withIdentifier: ConversationViewController.segueIdentifier, sender: nil)
                } else {
                    self.displayAlert(title: nil, message: "Error creating UserGroup, please try again")
                }
            })
        }
    }
}


// MARK: UITextFieldDelegate

extension NewMessageViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    @IBAction func searchBarTextFieldEditingChanged(_ sender: SearchBarTextField) {
        self.filterUsers()
    }
}


// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension NewMessageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = selectedUsers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AvatarCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as! AvatarCollectionViewCell
        
        cell.avatarView.set(user: user)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = selectedUsers.remove(at: indexPath.row)
        filteredUsers.append(user)
        filteredUsers.sort()
        
        self.reloadData()
    }
}


// MARK: UITableViewDataSource, UITableViewDelegate

extension NewMessageViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = filteredUsers[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PeopleTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! PeopleTableViewCell
        
        cell.avatarView.set(user: user)
        cell.nameLabel.text = user.fullName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = filteredUsers.remove(at: indexPath.row)
        selectedUsers.append(user)
        
        self.reloadData()
    }
}


// MARK: - UICollectionViewDelegateFlowLayout

extension NewMessageViewController: UICollectionViewDelegateFlowLayout {
    fileprivate var sectionInsets: UIEdgeInsets {
        let count = CGFloat(Int(selectedUsers.count) / 2)
        let center = (collectionView.frame.size.width / 2.0) - (itemSize / 2.0)
        
        let offset = self.selectedUsers.count % 2 == 0 ?
            ((self.itemSize + self.interItemSpace) * count) - ((self.itemSize / 2.0) + (self.interItemSpace / 2.0))
            : ((self.itemSize + self.interItemSpace) * count)
        
        let leftInset = center - offset
        
        return UIEdgeInsets(top: 0.0, left: max(0.0, leftInset), bottom: 0.0, right: 0.0)
    }
    
    fileprivate var interItemSpace: CGFloat {
        return 20.0
    }
    
    fileprivate var itemSize: CGFloat {
        return 40.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemSize, height: itemSize)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpace
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpace
    }
}
