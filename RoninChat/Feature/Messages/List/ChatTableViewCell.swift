import UIKit

class ChatTableViewCell: UITableViewCell {
    public static let reuseIdentifer: String = "ChatTableViewCell"
    public static let maximumNumberOfAvatarCells: Int = 6
    
    @IBOutlet var avatarCollectionView: UICollectionView!
    @IBOutlet var unreadView: UIView!
    @IBOutlet var titleLabelLeadingConstraintToUnreadView: NSLayoutConstraint!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    var users: [User] = []
    
    override func prepareForReuse() {
        users = []
        avatarCollectionView.reloadData()
    }
    
    func setUnreadView(visible: Bool) {
        unreadView.isHidden = visible
        titleLabelLeadingConstraintToUnreadView.isActive = !visible
        timestampLabel.textColor = visible ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1)
    }
}


// MARK: - UICollectionViewDataSource

extension ChatTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(ChatTableViewCell.maximumNumberOfAvatarCells, users.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AvatarCollectionViewCell.reuseIdentifier, for: indexPath) as! AvatarCollectionViewCell
        let user = users[indexPath.row]
        
        if (indexPath.row < (ChatTableViewCell.maximumNumberOfAvatarCells - 1)
            || (users.count == ChatTableViewCell.maximumNumberOfAvatarCells)) {
                cell.avatarView.set(user: user)
        } else {
            cell.avatarView.label.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            cell.avatarView.label.text = "+\(users.count - (ChatTableViewCell.maximumNumberOfAvatarCells - 1))"
        }
        
        return cell
    }
}


// MARK: - UICollectionViewDelegateFlowLayout

extension ChatTableViewCell: UICollectionViewDelegateFlowLayout {
    fileprivate var sectionInsets: UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    fileprivate var itemsPerRow: CGFloat {
        return ChatTableViewCell.maximumNumberOfAvatarCells.cgFloat
    }
    
    fileprivate var interItemSpace: CGFloat {
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionPadding = sectionInsets.left * (itemsPerRow)
        let interItemPadding = max(0.0, itemsPerRow - 1) * interItemSpace
        let availableWidth = collectionView.bounds.width - sectionPadding - interItemPadding
        let widthPerItem =  min((availableWidth / itemsPerRow), collectionView.frame.size.height)
        
        return CGSize(width: widthPerItem, height: widthPerItem)
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
