import UIKit

class ChannelTableViewCell: UITableViewCell {
    public static let reuseIdentifier: String = "ChannelTableViewCell"
    
    @IBOutlet var unreadView: RoundedView!
    @IBOutlet var titleLabelLeadingConstraintToUnreadView: NSLayoutConstraint!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var purposelabel: UILabel!
    
    @IBOutlet var lastMessageView: UIView!
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var lastMessageLabel: UILabel!
}
