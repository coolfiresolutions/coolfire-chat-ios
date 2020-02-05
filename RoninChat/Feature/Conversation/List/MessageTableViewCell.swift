import UIKit

class MessageTableViewCell: UITableViewCell {
    public static let reuseIdentifier: String = "MessageTableViewCell"
    
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var messageTextView: UITextView!
    @IBOutlet var attachmentIconImageView: UIImageView!
    @IBOutlet var attachmentImageView: UIImageView!
    
    @IBOutlet var textViewAlignmentConstraintToAvatarView: NSLayoutConstraint!
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        setAttachment(visible: false)
        attachmentIconImageView.isHidden = false
        attachmentImageView.af_cancelImageRequest()
        attachmentImageView.image = nil
    }
    
    func setAttachment(visible: Bool) {
        textViewAlignmentConstraintToAvatarView.isActive = !visible
        imageViewBottomConstraint.isActive = visible
        attachmentImageView.isHidden = !visible
    }
}
