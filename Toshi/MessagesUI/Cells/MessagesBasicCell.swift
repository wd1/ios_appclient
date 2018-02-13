import Foundation
import UIKit
import TinyConstraints

enum MessagePositionType {
    case single
    case top
    case middle
    case bottom
}

enum OutGoingMessageSentState {
    case undefined
    case sent
    case sending
    case failed
}

protocol MessagesBasicCellDelegate: class {
    func didTapAvatarImageView(from cell: MessagesBasicCell)
}

/* Messages Basic Cell:
 This UITableViewCell is the base cell for the different
 advanced cells used in messages. It provides the ground layout. */

class MessagesBasicCell: UITableViewCell {

    private let contentLayoutGuide = UILayoutGuide()
    private let leftLayoutGuide = UILayoutGuide()
    private let centerLayoutGuide = UILayoutGuide()
    private let rightLayoutGuide = UILayoutGuide()
    private let bottomLayoutGuide = UILayoutGuide()

    private(set) var leftWidthConstraint: NSLayoutConstraint?
    private(set) var rightWidthConstraint: NSLayoutConstraint?

    private(set) lazy var bubbleView: UIView = {
        let view = UIView()
        view.clipsToBounds = true

        return view
    }()

    private(set) lazy var messagesCornerView: MessagesCornerView = MessagesCornerView()

    private(set) lazy var avatarImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 18
        view.isUserInteractionEnabled = true

        return view
    }()

    private(set) lazy var errorView: MessagesErrorView = {
        let view = MessagesErrorView()
        view.alpha = 0

        return view
    }()

    private(set) lazy var errorlabel: UILabel = {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attributes: [NSAttributedStringKey: Any] = [
            .font: Theme.preferredFootnote(),
            .foregroundColor: Theme.errorColor,
            .paragraphStyle: paragraphStyle
        ]

        let boldAttributes: [NSAttributedStringKey: Any] = [
            .font: Theme.semibold(size: 13),
            .foregroundColor: Theme.errorColor,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSMutableAttributedString(string: Localized("messages_sent_error"), attributes: attributes)
        attributedString.addAttributes(boldAttributes, range: NSRange(location: 0, length: 13))

        let view = UILabel()
        view.alpha = 0
        view.attributedText = attributedString
        view.adjustsFontForContentSizeCategory = true
        view.numberOfLines = 1

        return view
    }()

    private let margin: CGFloat = 10
    private let avatarRadius: CGFloat = 44

    private var bubbleLeftConstraint: NSLayoutConstraint?
    private var bubbleRightConstraint: NSLayoutConstraint?
    private var bubbleLeftConstantConstraint: NSLayoutConstraint?
    private var bubbleRightConstantConstraint: NSLayoutConstraint?
    private var contentLayoutGuideTopConstraint: NSLayoutConstraint?
    private var bottomLayoutGuideHeightConstraint: NSLayoutConstraint?

    private lazy var avatarTapGestureRecogniser: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(didTapAvatarImageView(_:)))
    }()

    weak var delegate: MessagesBasicCellDelegate?

    var isOutGoing: Bool = false {
        didSet {
            if isOutGoing {
                bubbleRightConstraint?.isActive = false
                bubbleLeftConstantConstraint?.isActive = false
                bubbleLeftConstraint?.isActive = true
                bubbleRightConstantConstraint?.isActive = true
            } else {
                bubbleLeftConstraint?.isActive = false
                bubbleRightConstantConstraint?.isActive = false
                bubbleRightConstraint?.isActive = true
                bubbleLeftConstantConstraint?.isActive = true
            }
        }
    }

    var positionType: MessagePositionType = .single {
        didSet {
            let isFirstMessage = positionType == .single || positionType == .top
            contentLayoutGuideTopConstraint?.constant = isFirstMessage ? 8 : 4

            let isAvatarHidden = positionType == .middle || positionType == .top || isOutGoing
            avatarImageView.isHidden = isAvatarHidden

            messagesCornerView.setImage(for: positionType, isOutGoing: isOutGoing, isPayment: self is MessagesPaymentCell)
        }
    }

    var sentState: OutGoingMessageSentState = .undefined {
        didSet {
            switch sentState {
            case .undefined, .sent, .sending:
                showSentError(false)
            case .failed:
                showSentError(true)
            }
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = nil
        selectionStyle = .none
        contentView.autoresizingMask = [.flexibleHeight]

        /* Layout Guides:
         The leftLayoutGuide reserves space for an optional avatar.
         The centerLayoutGuide defines the space for the message content.
         The rightLayoutGuide reserves space for an optional error indicator. */

        [contentLayoutGuide, leftLayoutGuide, centerLayoutGuide, rightLayoutGuide, bottomLayoutGuide].forEach {
            contentView.addLayoutGuide($0)
        }

        contentLayoutGuideTopConstraint = contentLayoutGuide.top(to: contentView, offset: 2)
        contentLayoutGuide.left(to: contentView)
        contentLayoutGuide.right(to: contentView)
        contentLayoutGuide.width(UIScreen.main.bounds.width)

        leftLayoutGuide.top(to: contentLayoutGuide)
        leftLayoutGuide.left(to: contentLayoutGuide, offset: margin)
        leftLayoutGuide.bottom(to: contentLayoutGuide)

        centerLayoutGuide.top(to: contentLayoutGuide)
        centerLayoutGuide.leftToRight(of: leftLayoutGuide)
        centerLayoutGuide.bottom(to: contentLayoutGuide)

        rightLayoutGuide.top(to: contentLayoutGuide)
        rightLayoutGuide.leftToRight(of: centerLayoutGuide)
        rightLayoutGuide.bottom(to: contentLayoutGuide)
        rightLayoutGuide.right(to: contentLayoutGuide, offset: -margin)

        leftWidthConstraint = leftLayoutGuide.width(avatarRadius)
        rightWidthConstraint = rightLayoutGuide.width(0)

        bottomLayoutGuide.topToBottom(of: contentLayoutGuide)
        bottomLayoutGuide.left(to: contentView, offset: 10)
        bottomLayoutGuide.bottom(to: contentView)
        bottomLayoutGuide.right(to: contentView, offset: -10)

        bottomLayoutGuideHeightConstraint = bottomLayoutGuide.height(0)

        /* Avatar Image View:
         A UIImageView for showing an optional avatar of the user. */

        contentView.addSubview(avatarImageView)
        avatarImageView.left(to: leftLayoutGuide)
        avatarImageView.bottom(to: leftLayoutGuide)
        avatarImageView.right(to: leftLayoutGuide, offset: -8)
        avatarImageView.height(to: avatarImageView, avatarImageView.widthAnchor)

        /* Bubble View:
         The container that can be filled with a message, image or
         even a payment request. */

        contentView.addSubview(bubbleView)
        bubbleView.top(to: centerLayoutGuide)
        bubbleView.bottom(to: centerLayoutGuide)

        bubbleLeftConstraint = bubbleView.left(to: centerLayoutGuide, offset: 50, relation: .equalOrGreater)
        bubbleRightConstraint = bubbleView.right(to: centerLayoutGuide, offset: -50, relation: .equalOrLess)
        bubbleLeftConstantConstraint = bubbleView.left(to: centerLayoutGuide, isActive: false)
        bubbleRightConstantConstraint = bubbleView.right(to: centerLayoutGuide, isActive: false)

        bubbleView.addSubview(messagesCornerView)
        messagesCornerView.edges(to: bubbleView)

        /* Error State:
         A red view that can animate in from the right to indicate that a
         message has failed to sent and a label that informs the user. */

        contentView.addSubview(errorView)
        errorView.edges(to: rightLayoutGuide)

        contentView.addSubview(errorlabel)
        errorlabel.edges(to: bottomLayoutGuide)

        avatarImageView.addGestureRecognizer(avatarTapGestureRecogniser)
    }

    func showSentError(_ show: Bool, animated: Bool = false) {

        rightWidthConstraint?.constant = show ? 30 : 0
        bottomLayoutGuideHeightConstraint?.constant = show ? 30 : 0

        if animated {
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
                self.errorView.alpha = show ? 1 : 0
                self.errorlabel.alpha = show ? 1 : 0

                if self.superview != nil {
                    self.layoutIfNeeded()
                }
            }, completion: nil)
        } else {
            errorView.alpha = show ? 1 : 0
            errorlabel.alpha = show ? 1 : 0

            if superview != nil {
                layoutIfNeeded()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        messagesCornerView.image = nil
        sentState = .undefined
        isUserInteractionEnabled = true
    }

    @objc private func didTapAvatarImageView(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }

        delegate?.didTapAvatarImageView(from: self)
    }
}
