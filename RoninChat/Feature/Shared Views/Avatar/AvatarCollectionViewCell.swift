import UIKit

class AvatarCollectionViewCell: UICollectionViewCell {
    static public let nibName: String = "AvatarCollectionViewCell"
    static public let reuseIdentifier: String = "AvatarCollectionViewCell"
    
    @IBOutlet var avatarView: AvatarView!
    
    override func prepareForReuse() {
        avatarView.label.backgroundColor = #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1)
    }
}
