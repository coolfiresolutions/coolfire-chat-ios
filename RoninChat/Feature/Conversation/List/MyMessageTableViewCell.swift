import UIKit

class MyMessageTableViewCell: UITableViewCell {
    public static let reuseIdentifier: String = "MyMessageTableViewCell"
    
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var messageTextView: MessageTextView!
    @IBOutlet var attachmentIconImageView: UIImageView!
    @IBOutlet var attachmentImageView: UIImageView!
    
    @IBOutlet var textViewAlignmentConstraintToSuperView: NSLayoutConstraint!
    @IBOutlet var imageViewBottomConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        setAttachment(visible: false)
        attachmentIconImageView.isHidden = false
        attachmentImageView.af_cancelImageRequest()
        attachmentImageView.image = nil
    }
    
    func setAttachment(visible: Bool) {
        textViewAlignmentConstraintToSuperView.isActive = !visible
        imageViewBottomConstraint.isActive = visible
        attachmentImageView.isHidden = !visible
    }
}
