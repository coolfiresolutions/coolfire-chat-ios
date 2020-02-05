import UIKit

class MessagesViewController: UIViewController {
    @IBOutlet var loaderView: LoaderView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableStatusView: TableStatusView!
    
    @IBAction func unwindFromNewMessageViewController(sender: UIStoryboardSegue) {}
    
    var conversations: [Messageable] = []
    var selectedIndex: IndexPath?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerObservers()
        initRefreshControl()
        getConversations()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ConversationViewController.segueIdentifier,
            let viewController = segue.destination as? ConversationViewController {
            
                let conversation = conversations[selectedIndex?.row ?? 0]
                conversation.unreadMessageCount = 0
                tableView.reloadRows(at: [IndexPath(row: selectedIndex?.row ?? 0, section: 0)], with: .automatic)
                viewController.conversation = conversation
                selectedIndex = nil
            
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func registerObservers() {
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
    
    func initRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.tintColor = #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1)
        tableView.refreshControl?.addTarget(self, action: #selector(getConversations), for: .valueChanged)
        tableView.contentOffset = CGPoint(x: 0.0, y: -(self.tableView.refreshControl?.frame.size.height ?? 0.0))
    }
    
    @objc func getConversations() {
        self.tableView.refreshControl?.beginRefreshing()
        
        Ronin.shared.getConversations(completion: { conversations in
            self.tableView.refreshControl?.endRefreshing()
            self.loaderView.isHidden = true
            
            if let conversations = conversations {
                self.conversations = conversations
                self.tableStatusView.isHidden = false
                self.tableStatusView.isHidden = !self.conversations.isEmpty
                self.tableView.refreshControl?.endRefreshing()
            } else {
                self.conversations = []
                self.tableStatusView.set(image: #imageLiteral(resourceName: "img_loadErrors"))
                self.tableStatusView.set(labelText: "Error retrieving messages.")
                self.tableStatusView.isHidden = false
            }
            
            self.tableView.reloadData()
        })
    }
    
    @objc func didReceiveTextNotification(notification: Notification) {
        guard
            let notificationObject = notification.object as? [String: Any],
            let message = notificationObject[Notification.objectKey] as? RoninMessage,
            (message.targetType == .User || message.targetType == .UserGroup),
            let targetId = message.targetId as String?,
            let index = (targetId == Ronin.shared.authUser.id ?
                conversations.firstIndex(where: { $0.id == message.actorId.id }) :
                conversations.firstIndex(where: { $0.id == targetId })
            )
        else {
            return
        }
        
        let targetConversation = conversations[index]
        targetConversation.lastMessage = message
        targetConversation.unreadMessageCount = (message.actorId.id == Ronin.shared.authUser.id ? 0 : (targetConversation.unreadMessageCount + 1))
        conversations[index] = targetConversation
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        
        tableView.beginUpdates()
        conversations.remove(at: index)
        conversations.insert(targetConversation, at: 0)
        tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: 0, section: 0))
        tableView.endUpdates()
    }
    
    @objc func didReceiveUserGroupNotification(notification: Notification) {
        guard
            let notificationObject = notification.object as? [String: Any],
            let userGroup = notificationObject[Notification.objectKey] as? UserGroup,
            let action = notificationObject[Notification.actionKey] as? RoninMessage.Action
        else {
            return
        }
        
        switch action {
        case .Create:
            tableStatusView.isHidden = true
            tableView.beginUpdates()
            conversations.insert(userGroup, at: 0)
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
            tableView.endUpdates()
        case .Delete:
            guard let id = userGroup.id, let index = conversations.firstIndex(where: { $0.id == id }) else { return }
                    
            tableStatusView.isHidden = !conversations.isEmpty
            tableView.beginUpdates()
            conversations.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
            tableView.endUpdates()
        case .Update:
            guard let id = userGroup.id, let index = conversations.firstIndex(where: { $0.id == id }), let conversation = conversations[index] as? UserGroup else { return }
            
            conversations[index] = conversation.updateBasedOnValues(userGroup)
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        default:
            return
        }
    }
}


// MARK: UITableViewDataSource, UITableViewDelege

extension MessagesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
        self.performSegue(withIdentifier: ConversationViewController.segueIdentifier, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatTableViewCell.reuseIdentifer,
            for: indexPath
        ) as! ChatTableViewCell
        let conversation = conversations[indexPath.row]
        
        switch conversation.entityType {
        case .User:
            if let user = conversation as? User {
                cell.setUnreadView(visible: user.unreadMessageCount == 0)
                cell.users = [user]
                cell.titleLabel.text = user.fullName
                cell.descriptionLabel.text = user.lastMessage?.messageDescription
                cell.timestampLabel.text = user.lastMessage?.sent.getElapsedInterval()
            }
        case .UserGroup:
            if let userGroup = conversation as? UserGroup {
                userGroup.users.removeAll(where: { $0.id == Ronin.shared.authUser.id })
                cell.setUnreadView(visible: userGroup.unreadMessageCount == 0)
                cell.users = userGroup.users
                cell.titleLabel.text = userGroup.name
                cell.descriptionLabel.text = userGroup.lastMessage?.messageDescription
                cell.timestampLabel.text = userGroup.lastMessage?.sent.getElapsedInterval() ?? userGroup.startDate?.getElapsedInterval()
            }
        default:
            print("Unhandled Conversation type in MessagesViewController")
        }
        
        return cell
    }
}
