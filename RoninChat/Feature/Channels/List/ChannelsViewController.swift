import UIKit

class ChannelsViewController: UIViewController {
    @IBOutlet var searchTextField: SearchBarTextField!
    @IBOutlet var loaderView: LoaderView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableStatusView: TableStatusView!
    
     @IBAction func unwindFromNewChannelViewController(sender: UIStoryboardSegue) {}
    
    var channels: [Channel] = []
    var filteredChannels: [Channel] = []
    var selectedIndex: IndexPath?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerObservers()
        initRefreshControl()
        getChannels()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ConversationViewController.segueIdentifier,
            let viewController = segue.destination as? ConversationViewController {
            
                let channel = filteredChannels[selectedIndex?.row ?? 0]
                channel.unreadMessageCount = 0
                tableView.reloadRows(at: [IndexPath(row: selectedIndex?.row ?? 0, section: 0)], with: .automatic)
                viewController.conversation = channel
            
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
            selector: #selector(didReceiveChannelNotification),
            name: Notification.channelNotification,
            object: nil
        )
    }
    
    func initRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.tintColor = #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1)
        tableView.refreshControl?.addTarget(self, action: #selector(getChannels), for: .valueChanged)
        tableView.contentOffset = CGPoint(x: 0.0, y: -(self.tableView.refreshControl?.frame.size.height ?? 0.0))
    }
    
    @objc func getChannels() {
        self.tableView.refreshControl?.beginRefreshing()
        
        Ronin.shared.getChannels(completion: { channels in
            self.tableView.refreshControl?.endRefreshing()
            self.loaderView.isHidden = true
            
            if let channels = channels {
                self.channels = channels
                self.tableStatusView.isHidden = true
                self.tableView.refreshControl?.endRefreshing()
            } else {
                self.channels = []
                self.tableStatusView.set(image: #imageLiteral(resourceName: "img_loadErrors"))
                self.tableStatusView.set(labelText: "Error retrieving channels.")
                self.tableStatusView.isHidden = false
            }
            
            self.filterChannels()
            self.tableView.reloadData()
        })
    }
    
    func filterChannels() {
        let text = searchTextField.text ?? ""
        
        self.filteredChannels = text.isEmpty ?
            channels :
            channels.filter({
                ($0.name ?? "").lowercased().contains(text.lowercased()) ||
                ($0.channelDescription ?? "").lowercased().contains(text.lowercased())
            })
    }
    
    @objc func didReceiveTextNotification(notification: Notification) {
        guard
            let notificationObject = notification.object as? [String: Any],
            let message = notificationObject[Notification.objectKey] as? RoninMessage,
            message.targetType == .Session,
            let targetId = message.targetId as String?,
            let targetChannel = channels.first(where: { $0.id == targetId }),
            let index = channels.firstIndex(of: targetChannel)
        else {
            return
        }
        
        targetChannel.lastMessage = message
        targetChannel.unreadMessageCount = (message.actorId.id == Ronin.shared.authUser.id ? 0 : (targetChannel.unreadMessageCount + 1))
        channels[index] = targetChannel
        
        if let filteredIndex = filteredChannels.firstIndex(where: { $0.id == targetId }) {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            tableView.beginUpdates()
            channels.move(at: index, to: 0)
            tableView.moveRow(at: IndexPath(row: filteredIndex, section: 0), to: IndexPath(row: 0, section: 0))
            tableView.endUpdates()
        } else {
            channels.move(at: index, to: 0)
        }
        
        filterChannels()
    }
    
    @objc func didReceiveChannelNotification(notification: Notification) {
        guard
            let notificationObject = notification.object as? [String: Any],
            let channel = notificationObject[Notification.objectKey] as? Channel,
            let action = notificationObject[Notification.actionKey] as? RoninMessage.Action
        else {
            return
        }
        
        switch action {
        case .Create:
            tableStatusView.isHidden = true
            channels.insert(channel, at: 0)
            filterChannels()
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
            tableView.endUpdates()
        case .Delete:
            guard let id = channel.id, let index = channels.firstIndex(where: { $0.id == id }) else { return }
            
            channels.remove(at: index)
            tableStatusView.isHidden = !channels.isEmpty
            
            if let filteredIndex = filteredChannels.firstIndex(where: { $0.id == id }) {
                tableView.beginUpdates()
                filteredChannels.remove(at: filteredIndex)
                tableView.deleteRows(at: [IndexPath(row: filteredIndex, section: 0)], with: .left)
                tableView.endUpdates()
            }
        case .Update:
            guard let id = channel.id, let index = channels.firstIndex(where: { $0.id == id }) else { return }
            _ = channels[index].updateBasedOnValues(channel)
            
            if let filteredIndex = filteredChannels.firstIndex(where: { $0.id == id }) {
                tableView.reloadRows(at: [IndexPath(row: filteredIndex, section: 0)], with: .automatic)
            }
        default:
            return
        }
    }
}


// MARK: UITextFieldDelegate

extension ChannelsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    @IBAction func searchBarTextFieldEditingChanged(_ sender: SearchBarTextField) {
        self.filterChannels()
        self.tableView.reloadData()
    }
}


// MARK: UITableViewDataSource, UITableViewDelege

extension ChannelsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredChannels.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let channel = filteredChannels[indexPath.row]
        return channel.lastMessage != nil ? 150 : 104
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let channel = filteredChannels[indexPath.row]
        return channel.lastMessage != nil ? 150 : 104
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
        self.performSegue(withIdentifier: ConversationViewController.segueIdentifier, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChannelTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! ChannelTableViewCell
        let channel = filteredChannels[indexPath.row]
        
        
        cell.unreadView.isHidden = (channel.unreadMessageCount == 0)
        cell.titleLabelLeadingConstraintToUnreadView.isActive = !cell.unreadView.isHidden
        cell.titleLabel.text = channel.name
        cell.purposelabel.text = channel.channelDescription
        
        cell.lastMessageView.isHidden = (channel.lastMessage == nil)
        
        if let user = Ronin.shared.users.first(where: { $0.id == (channel.lastMessage?.actorId.id ?? "") }) {
            cell.avatarView.set(user: user)
            cell.nameLabel.text = user.fullName
            cell.lastMessageLabel.text = channel.lastMessage?.messageDescription
        }
        
        return cell
    }
}
