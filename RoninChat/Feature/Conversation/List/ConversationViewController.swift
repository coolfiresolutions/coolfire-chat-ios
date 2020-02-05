import UIKit

class ConversationViewController: UIViewController {
    public static let segueIdentifier: String = "showConversationViewController"
    public static let unwindSegueIdentifier: String = "unwindFromConversationViewController"
    
    @IBOutlet var loaderView: LoaderView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableStatusView: TableStatusView!
    @IBOutlet var expandableHeaderView: ExpandableHeaderView!
    @IBOutlet var expandableHeaderViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var messageTextField: UnderlinedTextField!
    @IBOutlet var messageSendButton: UIButton!
    @IBOutlet var messageActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var messageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var attachmentImageView: UIImageView!
    @IBOutlet var attachmentCancelButton: UIButton!
    
    @IBAction func unwindFromChannelDetailsViewController(sender: UIStoryboardSegue) {}
    @IBAction func unwindFromGroupDetailsViewController(sender: UIStoryboardSegue) {}
    
    var conversation: Messageable?
    var users: [User] = []
    var messages: [RoninMessage] = []
    var attachment: Attachment?
    
    var channelDescription: String { get { return (conversation as? Channel)?.channelDescription ?? "" }}
    var channelTitle: String {
        get {
            switch conversation?.entityType ?? .Other {
            case .Session:
                return (conversation as? Channel)?.name ?? "Unknown"
            case .User:
                return (conversation as? User)?.fullName ?? "Unknown"
            case .UserGroup:
                return (conversation as? UserGroup)?.name ?? "Unknown"
            default:
                return "Unknown"
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerObservers()
        initTapGesture()
        initUsers()
        initExpandableHeaderView()
        getMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom(animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentInsetForTableView(tableView: tableView, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ConversationViewController.segueIdentifier,
            let viewController = segue.destination as? ConversationViewController {
            
                let user = self.expandableHeaderView.cardView.avatarView.user
                viewController.conversation = user
            
        } else if segue.identifier == ChannelDetailsViewController.segueIdentifier,
            let viewController = segue.destination as? ChannelDetailsViewController {
            
                viewController.delegate = self
                viewController.channel = (conversation as? Channel)
            
        } else if segue.identifier == GroupDetailsViewController.segueIdentifier,
            let viewController = segue.destination as? GroupDetailsViewController {
            
                viewController.delegate = self
                viewController.group = (conversation as? UserGroup)
            
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func registerObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveChannelNotification),
            name: Notification.channelNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveTextNotification),
            name: Notification.textNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveUserGroupNotification),
            name: Notification.userGroupNotification,
            object: nil
        )
    }
    
    func initTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        self.tableView.addGestureRecognizer(tap)
    }
    
    func initUsers() {
        switch conversation?.entityType ?? .Other {
        case .Session:
            users = (conversation as? Channel)?.users ?? []
        case .User:
            let user = (conversation as? User)
            users = user == nil ? [] : [user!]
        case .UserGroup:
            users = (conversation as? UserGroup)?.users ?? []
        default:
            print("Unknown Conversation type in ConversationViewController")
        }
    }
    
    func initExpandableHeaderView() {
        expandableHeaderView.titleLabel.text = channelTitle
        expandableHeaderView.deleteButtonLabel.text = (conversation?.entityType ?? .Other) == .Session ? "Delete" : "Remove"
        expandableHeaderView.users = users
    }
    
    func setAttachment(visible: Bool) {
        if !visible {
            attachment = nil
            attachmentImageView.image = nil
        }
        
        messageTextFieldEditingChanged(messageTextField)
        attachmentImageView.isHidden = !visible
        attachmentCancelButton.isHidden = !visible
        messageViewHeightConstraint.isActive = !visible
    }
    
    func getMessages() {
        guard let conversation = self.conversation else { return }
        
        Ronin.shared.getMessages(for: conversation, completion: { messages in
            self.loaderView.isHidden = true
            
            if let messages = messages {
                self.tableStatusView.isHidden = !messages.isEmpty
                self.messages = messages
                self.tableView.reloadData()
                self.updateInsetAndScrollToBottom()
            } else {
                self.tableStatusView.set(image: #imageLiteral(resourceName: "img_loadErrors"))
                self.tableStatusView.set(labelText: "Error retrieving conversation.")
                self.tableStatusView.isHidden = false
            }
        })
    }
    
    func add(message: RoninMessage) {
        tableStatusView.isHidden = true
        
        tableView.beginUpdates()
        messages.append(message)
        tableView.insertRows(at: [IndexPath(row: self.messages.count - 1, section: 0)], with: .bottom)
        tableView.endUpdates()
        
        if tableView.scrolledToBottom {
            updateInsetAndScrollToBottom()
        }
    }
    
    @objc func didReceiveChannelNotification(notification: Notification) {
        guard
            let conversation = self.conversation as? Channel,
            let notificationObject = notification.object as? [String: Any],
            let channel = notificationObject[Notification.objectKey] as? Channel,
            let action = notificationObject[Notification.actionKey] as? RoninMessage.Action
        else {
            return
        }
        
        switch action {
        case .Delete:
            self.displayAlert(title: "Channel Deleted", message: "This channel has been deleted", handler: { alert in
                self.performSegue(withIdentifier: ConversationViewController.unwindSegueIdentifier, sender: nil)
            })
        case .Update:
            self.conversation = conversation.updateBasedOnValues(channel)
            initUsers()
            initExpandableHeaderView()
        default:
            return
        }
    }
    
    @objc func didReceiveTextNotification(notification: Notification) {
        guard
            let notificationObject = notification.object as? [String: Any],
            let message = notificationObject[Notification.objectKey] as? RoninMessage,
            let targetId = message.targetId as String?
        else {
            return
        }
        
        switch conversation?.entityType ?? .Other {
        case .Session, .UserGroup:
            guard targetId == self.conversation?.id else { return }
        case .User:
            guard targetId == Ronin.shared.authUser.id || targetId == self.conversation?.id else { return }
        default:
            return
        }
        
        add(message: message)
    }
    
    @objc func didReceiveUserGroupNotification(notification: Notification) {
        guard
            let conversation = self.conversation as? UserGroup,
            let notificationObject = notification.object as? [String: Any],
            let userGroup = notificationObject[Notification.objectKey] as? UserGroup,
            let action = notificationObject[Notification.actionKey] as? RoninMessage.Action
        else {
            return
        }
        
        switch action {
        case .Delete:
            self.displayAlert(title: "Group Deleted", message: "This group has been deleted", handler: { alert in
                self.performSegue(withIdentifier: ConversationViewController.unwindSegueIdentifier, sender: nil)
            })
        case .Update:
            self.conversation = conversation.updateBasedOnValues(userGroup)
            initUsers()
            initExpandableHeaderView()
        default:
            return
        }
    }
    
    
    // MARK: UI Actions
    
    @objc func handleTap() {
        expandableHeaderView.animate(to: .collapsed)
        dismissKeyboard()
    }
    
    @IBAction func messageAddButtonTouchUpInside(_ sender: UIButton) {
        showPhotoLibrary()
    }
    
    @IBAction func messageSendButtonTouchUpInside(_ sender: UIButton) {
        guard
            let id = conversation?.id,
            let entityType = conversation?.entityType.rawValue,
            let scopeType = RoninMessage.ScopeType(rawValue: entityType),
            let body = messageTextField.text
        else {
            displayAlert(title: "Error sending message", message: "Please try again")
            return
        }
        
        self.messageSendButton.isEnabled = false
        self.messageSendButton.isHidden = true
        self.messageActivityIndicator.startAnimating()
        
        Ronin.shared.sendMessage(to: id, body: body, attachment: attachment, scopeType: scopeType, completion: { roninMessage in
            if roninMessage != nil {
                self.messageTextField.text = ""
                self.messageSendButton.tintColor = #colorLiteral(red: 0.5721980333, green: 0.5800120234, blue: 0.6048780084, alpha: 1)
            } else {
                self.messageSendButton.isEnabled = true
                self.displayAlert(title: "Error sending message", message: "Please try again")
            }
            
            self.messageActivityIndicator.stopAnimating()
            self.messageSendButton.isHidden = false
            self.setAttachment(visible: false)
        })
    }
    
    @IBAction func attachmentCancelButtonOnTouchUpInside(_ sender: UIButton) {
        setAttachment(visible: false)
    }
    
    
    // MARK: Utility Functions
    
    func updateContentInsetForTableView(tableView: UITableView, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let lastRow = tableView.numberOfRows(inSection: 0)
        let lastIndex = lastRow > 0 ? lastRow - 1 : 0
        let lastIndexPath = IndexPath(row: lastIndex, section: 0)
        
        let lastCellFrame = tableView.rectForRow(at: lastIndexPath)
        let topInset = max(tableView.frame.height - lastCellFrame.origin.y - lastCellFrame.height, 0)
        
        var contentInset = tableView.contentInset
        contentInset.top = topInset
        
        UIView.animate(withDuration: animated ? 0.5 : 0.0, animations: { () -> Void in
            tableView.contentInset = contentInset
        }, completion: completion)
    }
    
    func scrollToBottom(animated: Bool) {
        guard !self.messages.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.tableView.scrollToRow(
                at: IndexPath(row: self.messages.count - 1, section: 0),
                at: .bottom,
                animated: animated
            )
        }
    }
    
    func updateInsetAndScrollToBottom() {
        DispatchQueue.main.async {
            self.updateContentInsetForTableView(tableView: self.tableView, animated: false, completion: { completed in
                if completed {
                    self.scrollToBottom(animated: true)
                }
            })
        }
    }
    
    func showPhotoLibrary() {
        let pc = UIImagePickerController()
        pc.delegate = self
        pc.allowsEditing = true
        pc.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        pc.sourceType = .photoLibrary
        self.present(pc, animated: true, completion: nil)
    }
}


// MARK: UITextFieldDelegate

extension ConversationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard messageSendButton.isEnabled else { return false }
        self.messageSendButtonTouchUpInside(messageSendButton)
        return true
    }
    
    @IBAction func messageTextFieldEditingChanged(_ sender: UITextField) {
        messageSendButton.isEnabled = ((attachment != nil) || !(sender.text ?? "").isEmpty)
        messageSendButton.tintColor = messageSendButton.isEnabled ? #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1) : #colorLiteral(red: 0.5721980333, green: 0.5800120234, blue: 0.6048780084, alpha: 1)
    }
}


// MARK: ChannelDetailsViewControllerDelegate, GroupDetailsViewControllerDelegate

extension ConversationViewController: ChannelDetailsViewControllerDelegate, GroupDetailsViewControllerDelegate {
    func channelDetailsDidSave(title: String, description: String) {
        self.expandableHeaderView.titleLabel.text = title
        
        if let channel = (self.conversation as? Channel) {
            channel.name = title
            channel.channelDescription = description
            self.conversation = channel
        }
    }
    
    func groupDetailsDidSave(title: String) {
        self.expandableHeaderView.titleLabel.text = title
        
        if let group = (self.conversation as? UserGroup) {
            group.name = title
            self.conversation = group
        }
    }
}


// MARK: ExpandableHeaderViewDelegate

extension ConversationViewController: ExpandableHeaderViewDelegate {
    func isAnimatingTo(_ height: CGFloat) {
        self.expandableHeaderViewHeightConstraint.constant = height
    }
    
    func leftButtonTouchUpInside(_ sender: UIButton) {
        if !expandableHeaderView.isExpanded {
            self.performSegue(withIdentifier: ConversationViewController.unwindSegueIdentifier, sender: nil)
        }
    }
    
    func showDetailsButtonTouchUpInside(_ sender: UIButton) {
        if let _ = conversation as? Channel {
            self.performSegue(withIdentifier: ChannelDetailsViewController.segueIdentifier, sender: nil)
        } else {
            self.performSegue(withIdentifier: GroupDetailsViewController.segueIdentifier, sender: nil)
        }
    }
    
    func deleteButtonTouchUpInside(_ sender: UIButton) {
        let customAlertView = self.getCustomAlertView()
        customAlertView.delegate = self
        self.present(customAlertView, animated: true, completion: nil)
    }
    
    func userCardButtonTouchUpInside() {
        self.performSegue(withIdentifier: ConversationViewController.segueIdentifier, sender: nil)
    }
}


// MARK: CustomAlertViewDelegate

extension ConversationViewController: CustomAlertViewDelegate {
    func customAlertDidLoad(_ customAlertView: CustomAlertView) {
        switch conversation?.entityType ?? .Other {
        case .Session:
            customAlertView.titleLabel.text = "Delete this channel?"
        case .User:
            customAlertView.titleLabel.text = "Remove this conversation?"
            customAlertView.rightButton.setTitle("REMOVE", for: .normal)
        case .UserGroup:
            customAlertView.titleLabel.text = "Remove this group?"
            customAlertView.rightButton.setTitle("REMOVE", for: .normal)
        default:
            print("Conversation type not handled in CustomAlertDialog in ConversationViewController")
        }
    }
    
    func rightActionTapped() {
        if let channel = conversation as? Channel, let id = channel.id {
            Ronin.shared.deleteChannel(id, completion: { completed in
                if completed {
                    self.performSegue(withIdentifier: ConversationViewController.unwindSegueIdentifier, sender: nil)
                } else {
                    self.displayAlert(title: "Could not complete", message: "Error deleting channel, please try again")
                }
            })
        } else if let user = conversation as? User, let id = user.id {
            Ronin.shared.removeUserConversation(id, completion: { completed in
                if completed {
                    self.performSegue(withIdentifier: ConversationViewController.unwindSegueIdentifier, sender: nil)
                } else {
                    self.displayAlert(title: "Could not complete", message: "Error removing user conversation, please try again")
                }
            })
        } else if let userGroup = conversation as? UserGroup, let id = userGroup.id {
            Ronin.shared.removeUserGroup(id, completion: { completed in
                if completed {
                    self.performSegue(withIdentifier: ConversationViewController.unwindSegueIdentifier, sender: nil)
                } else {
                    self.displayAlert(title: "Could not complete", message: "Error removing group, please try again")
                }
            })
        }
    }
    
    func leftActionTapped() {}
}


// MARK: UITableViewDataSource, UITableViewDelegate

extension ConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let actor = Ronin.shared.users.first(where: { $0.id == message.actorId.id })
        
        if actor?.id != Ronin.shared.authUser.id {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MessageTableViewCell.reuseIdentifier,
                for: indexPath
            ) as! MessageTableViewCell
            
            if actor != nil {
                cell.avatarView.set(user: actor!)
            } else {
                cell.avatarView.label.text = "-"
            }
            
            cell.nameLabel.text = actor?.fullName ?? "Unknown user"
            cell.messageTextView.text = message.body
            cell.timestampLabel.text = message.sent.getElapsedIntervalAndTime()
            
            if
                !(message.attachments?.isEmpty ?? false),
                let attachment = message.attachments?[0],
                let url = (attachment.url ?? Ronin.shared.getFileDownloadUrl(fileID: attachment.id ?? "")),
                let urlRequest = try? URLRequest(url: url, method: .get, headers: Ronin.shared.roninServerInterface.defaultHeaders
            ) {
                cell.setAttachment(visible: true)
                cell.attachmentImageView.af_setImage(withURLRequest: urlRequest, completion: { response in
                    cell.attachmentIconImageView.isHidden = (response.data != nil)
                })
            }
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MyMessageTableViewCell.reuseIdentifier,
                for: indexPath
            ) as! MyMessageTableViewCell
            
            if
                !(message.attachments?.isEmpty ?? false),
                let attachment = message.attachments?[0],
                let url = (attachment.url ?? Ronin.shared.getFileDownloadUrl(fileID: attachment.id ?? "")),
                let urlRequest = try? URLRequest(url: url, method: .get, headers: Ronin.shared.roninServerInterface.defaultHeaders
            ) {
                cell.setAttachment(visible: true)
                cell.attachmentImageView.af_setImage(withURLRequest: urlRequest, completion: { response in
                    cell.attachmentIconImageView.isHidden = (response.data != nil)
                })
            }
            
            cell.messageTextView.text = message.body
            cell.timestampLabel.text = message.sent.getElapsedIntervalAndTime()
            
            return cell
        }
    }
}


// MARK : UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            guard let data = image.jpegData(compressionQuality: 1.0) else {
                print("Unable to convert image to JPEG")
                return
            }
            
            let attachment = Attachment(filename: "\(Date().timeIntervalSince1970).jpg", contentType: "image/jpeg", data: data)
            self.attachment = attachment
            self.attachmentImageView.image = image
            self.setAttachment(visible: true)
        } else {
            print("UIImagePickerController returned with an unknown media type")
        }
    }
}
