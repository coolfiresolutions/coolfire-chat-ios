import UIKit

@objc
public protocol ExpandableHeaderViewDelegate: NSObjectProtocol {
    @objc(isExpandingToHeight:)
    optional func isAnimatingTo(_ height: CGFloat)
    
    @objc(leftButtonTouchUpInsideWithSender:)
    optional func leftButtonTouchUpInside(_ sender: UIButton)
    
    @objc(rightButtonTouchUpInsideWithSender:)
    optional func rightButtonTouchUpInside(_ sender: UIButton)
    
    @objc(showDetailsButtonTouchUpInside:)
    optional func showDetailsButtonTouchUpInside(_ sender: UIButton)
    
    @objc(deleteButtonTouchUpInside:)
    optional func deleteButtonTouchUpInside(_ sender: UIButton)
    
    @objc(userCardButtonTouchUpInside)
    func userCardButtonTouchUpInside()
}

@IBDesignable
class ExpandableHeaderView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var viewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var cardView: UserCardView!
    @IBOutlet var menuView: UIStackView!
    @IBOutlet var detailsMenuItemView: UIView!
    @IBOutlet var detailsButtonLabel: UILabel!
    @IBOutlet var deleteMenuItemView: UIView!
    @IBOutlet var deleteButtonLabel: UILabel!
    
    @IBOutlet open weak var delegate: ExpandableHeaderViewDelegate?
    
    @IBInspectable var collapsedHeight: Int = 48 { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable var partiallyExpandedHeight: Int = 108 { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable var expandedHeight: Int = 162 { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable var menuHeight: Int = 160 { didSet { self.updateViewForInterfaceBuilder() }}
    
    @IBInspectable private(set) var isPartiallyExpanded: Bool = false { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable private(set) var isExpanded: Bool = false { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable private(set) var isMenuShown: Bool = false { didSet { self.updateViewForInterfaceBuilder() }}
    
    @IBInspectable var leftButtonImage: UIImage? = nil { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable var leftButtonExpandedImage: UIImage? = nil { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable var rightButtonImage: UIImage? = nil { didSet { self.updateViewForInterfaceBuilder() }}
    @IBInspectable var rightButtonMenuImage: UIImage? = nil { didSet { self.updateViewForInterfaceBuilder() }}
    
    private(set) var isAnimating: Bool = false
    private(set) var currentState: State = .collapsed
    var users: [User] = []
    
    public enum State {
        case collapsed
        case partiallyExpanded
        case expanded
        case menu
    }
    
    var currentStateHeight: Int {
        switch self.currentState {
        case .collapsed:
            return self.collapsedHeight
        case .partiallyExpanded:
            return self.partiallyExpandedHeight
        case .expanded:
            return self.expandedHeight
        case .menu:
            return self.menuHeight
        }
    }
    
    
    // MARK: Interface Builder Functions
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateViewForInterfaceBuilder()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }
    
    func setup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        collectionView.register(
            UINib(nibName: AvatarCollectionViewCell.nibName, bundle: nil),
            forCellWithReuseIdentifier: AvatarCollectionViewCell.reuseIdentifier
        )
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    func updateViewForInterfaceBuilder() {
        setHeightConstraint(currentStateHeight.cgFloat)
        updateButtonImages()
        setUI(for: currentState)
    }
    
    
    // MARK: UI
    
    func setHeightConstraint(_ height: CGFloat) {
        viewHeightConstraint.constant = height
    }
    
    func updateButtonImages(for state: State? = nil) {
        leftButton.setImage(
            (state ?? currentState) == .expanded ? (leftButtonExpandedImage ?? leftButtonImage) : leftButtonImage,
            for: .normal
        )
        rightButton.setImage(
            (state ?? currentState) == .menu ? (self.rightButtonMenuImage ?? rightButtonImage) : rightButtonImage,
            for: .normal
        )
    }
    
    func setUI(for state: State) {
        leftButton.alpha = (currentState == .menu ? 0.0 : 1.0)
        titleLabel.alpha = ((currentState == .expanded || currentState == .menu) ? 0.0 : 1.0)
        rightButton.alpha = ((currentState == .expanded) ? 0.0 : 1.0)
        detailsMenuItemView.isHidden = (users.count == 1)
        
        collectionView.alpha = (currentState == .partiallyExpanded ? 1.0 : 0.0)
        cardView.alpha = (currentState == .expanded ? 1.0 : 0.0)
        cardView.button.isHidden = (users.count == 1)
        menuView.alpha = (currentState == .menu ? 1.0 : 0.0)
    }
    
    func setUserCard(with user: User) {
        self.cardView.avatarView.set(user: user)
        self.cardView.nameLabel.text = user.fullName
        self.cardView.emailLabel.text = user.email
    }
    
    
    // MARK: UI Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentState == .collapsed, !users.isEmpty {
            if users.count == 1 {
                setUserCard(with: users[0])
            }
            
            animate(to: users.count > 1 ? .partiallyExpanded : .expanded)
        }
        
        super.touchesBegan(touches, with: event)
    }
    
    @IBAction func leftButtonTouchUpInside(_ sender: UIButton) {
        if currentState == .expanded {
            animate(to: users.count > 1 ? .partiallyExpanded : .collapsed)
        }
        
        if let function = self.delegate?.leftButtonTouchUpInside {
            function(sender)
        }
    }
    
    @IBAction func rightButtonTouchUpInside(_ sender: UIButton) {
        menuHeight = Int(
            collapsedHeight.cgFloat +
            (detailsMenuItemView.isHidden ? 0.0 : detailsMenuItemView.frame.height) +
            (deleteMenuItemView.isHidden ? 0.0 : deleteMenuItemView.frame.height)
        )
        
        animate(to: currentState == .menu ? .collapsed : .menu)
        
        if let function = self.delegate?.rightButtonTouchUpInside {
            function(sender)
        }
    }
    
    @IBAction func showDetailsButtonTouchUpInside(_ sender: UIButton) {
        if let function = self.delegate?.showDetailsButtonTouchUpInside {
            function(sender)
        }
    }
    
    @IBAction func deleteButtonTouchUpInside(_ sender: UIButton) {
        if let function = self.delegate?.deleteButtonTouchUpInside {
            function(sender)
        }
    }
    
    
    // MARK: Animation
    
    func animate(to state: State, withDuration: TimeInterval = 0.3) {
        guard !isAnimating else { return }
        
        currentState = state
        isAnimating = true
        
        UIView.animate(withDuration: withDuration, animations: {
            self.setHeightConstraint(self.currentStateHeight.cgFloat)
            self.updateButtonImages(for: state)
            self.setUI(for: state)
            self.view.layoutIfNeeded()
        }, completion: { completed in
            if completed {
                self.isAnimating = false
                self.isPartiallyExpanded = (state == .partiallyExpanded)
                self.isExpanded = (state == .expanded)
                self.isMenuShown = (state == .menu)
                
                if let function = self.delegate?.isAnimatingTo {
                    function(self.currentStateHeight.cgFloat)
                }
            }
        })
    }
}


// MARK: UserCardViewDelegate

extension ExpandableHeaderView: UserCardViewDelegate {
    func buttonTouchUpInside() {
        delegate?.userCardButtonTouchUpInside()
    }
}


// MARK: UICollectionViewDelegate, UICollectionViewDataSource

extension ExpandableHeaderView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AvatarCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? AvatarCollectionViewCell {
            let user = users[indexPath.row]
            cell.avatarView.set(user: user)
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        setUserCard(with: users[indexPath.row])
        animate(to: .expanded)
    }
}


// MARK: - UICollectionViewDelegateFlowLayout

extension ExpandableHeaderView: UICollectionViewDelegateFlowLayout {
    fileprivate var sectionInsets: UIEdgeInsets {
        let count = CGFloat(Int(users.count) / 2)
        let center = (collectionView.frame.size.width / 2.0) - (itemSize / 2.0)
        
        let offset = self.users.count % 2 == 0 ?
            ((self.itemSize + self.interItemSpace) * count) - ((self.itemSize / 2.0) + (self.interItemSpace / 2.0))
            : ((self.itemSize + self.interItemSpace) * count)
        
        let leftInset = center - offset
        
        return UIEdgeInsets(top: 0.0, left: max(0.0, leftInset), bottom: 0.0, right: 0.0)
    }
    
    fileprivate var interItemSpace: CGFloat {
        return 16.0
    }
    
    fileprivate var itemSize: CGFloat {
        return collectionView.frame.size.height * itemSizeScalar
    }
    
    fileprivate var itemSizeScalar: CGFloat {
        return 0.91
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
