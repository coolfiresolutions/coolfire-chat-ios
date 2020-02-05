import UIKit

class PeopleTableViewCell: UITableViewCell {
    public static let reuseIdentifier: String = "PeopleTableViewCell"
    
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel?
}
