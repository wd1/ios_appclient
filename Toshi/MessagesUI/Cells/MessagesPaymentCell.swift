import Foundation
import UIKit
import TinyConstraints

protocol MessagesPaymentCellDelegate: class {
    func approvePayment(for cell: MessagesPaymentCell)
    func declinePayment(for cell: MessagesPaymentCell)
}

class MessagesPaymentCell: MessagesBasicCell {

    weak var selectionDelegate: MessagesPaymentCellDelegate?

    static let reuseIdentifier = "MessagesPaymentCell"

    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredRegular()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.tintColor

        return view
    }()

    private(set) lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredRegularSmall()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.mediumTextColor

        return view
    }()

    private(set) lazy var messageLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredFootnote()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.darkTextColor

        return view
    }()

    private(set) lazy var statusLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.preferredFootnote()
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Theme.mediumTextColor

        return view
    }()

    private(set) lazy var approveButton: IconLabelButton = {
        let view = IconLabelButton()
        view.title = Localized("messages_payment_approve")
        view.icon = UIImage(named: "approve")?.withRenderingMode(.alwaysTemplate)
        view.color = Theme.tintColor
        view.addTarget(self, action: #selector(approvePayment(_:)), for: .touchUpInside)

        return view
    }()

    private(set) lazy var declineButton: IconLabelButton = {
        let view = IconLabelButton()
        view.title = Localized("messages_payment_decline")
        view.icon = UIImage(named: "decline")?.withRenderingMode(.alwaysTemplate)
        view.color = .gray
        view.addTarget(self, action: #selector(declinePayment(_:)), for: .touchUpInside)

        return view
    }()

    private var textBottomConstraint: NSLayoutConstraint?
    private var statusBottomConstraint: NSLayoutConstraint?
    private var buttonBottomConstraint: NSLayoutConstraint?

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let verticalMargin: CGFloat = 10
        let horizontalMargin: CGFloat = 15

        bubbleView.addSubview(titleLabel)
        bubbleView.addSubview(subtitleLabel)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(statusLabel)
        bubbleView.addSubview(approveButton)
        bubbleView.addSubview(declineButton)

        titleLabel.top(to: bubbleView, offset: verticalMargin)
        titleLabel.left(to: bubbleView, offset: horizontalMargin)
        titleLabel.right(to: bubbleView, offset: -horizontalMargin)

        subtitleLabel.topToBottom(of: titleLabel, offset: verticalMargin / 2)
        subtitleLabel.left(to: bubbleView, offset: horizontalMargin)
        subtitleLabel.right(to: bubbleView, offset: -horizontalMargin)

        messageLabel.topToBottom(of: subtitleLabel, offset: verticalMargin)
        messageLabel.left(to: bubbleView, offset: horizontalMargin)
        messageLabel.right(to: bubbleView, offset: -horizontalMargin)

        statusLabel.topToBottom(of: messageLabel, offset: verticalMargin)
        statusLabel.left(to: bubbleView, offset: horizontalMargin)
        statusLabel.right(to: bubbleView, offset: -horizontalMargin)

        approveButton.topToBottom(of: statusLabel, offset: verticalMargin)
        approveButton.left(to: bubbleView)
        approveButton.right(to: bubbleView)
        approveButton.height(50)

        declineButton.topToBottom(of: approveButton)
        declineButton.left(to: bubbleView)
        declineButton.right(to: bubbleView)
        declineButton.height(50)

        textBottomConstraint = messageLabel.bottom(to: bubbleView, offset: -verticalMargin, priority: .defaultHigh)
        statusBottomConstraint = statusLabel.bottom(to: bubbleView, offset: -verticalMargin, priority: .defaultHigh, isActive: false)
        buttonBottomConstraint = declineButton.bottom(to: bubbleView, priority: .defaultHigh, isActive: false)
    }

    func setPaymentState(_ state: PaymentState, paymentStateText: String, for type: MessageType) {

        if isOutGoing || type == .payment {
            approveButton.isHidden = true
            declineButton.isHidden = true
            statusLabel.isHidden = true

            statusBottomConstraint?.isActive = false
            buttonBottomConstraint?.isActive = false
            textBottomConstraint?.isActive = true
        } else if state == .none {
            approveButton.isHidden = false
            declineButton.isHidden = false
            statusLabel.isHidden = true

            textBottomConstraint?.isActive = false
            statusBottomConstraint?.isActive = false
            buttonBottomConstraint?.isActive = true
        } else {
            approveButton.isHidden = true
            declineButton.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = paymentStateText

            textBottomConstraint?.isActive = false
            buttonBottomConstraint?.isActive = false
            statusBottomConstraint?.isActive = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = nil
        subtitleLabel.text = nil
        messageLabel.text = nil
        statusLabel.text = nil

        setPaymentState(.none, paymentStateText: "", for: .payment)
    }

    @objc func approvePayment(_: IconLabelButton) {
        selectionDelegate?.approvePayment(for: self)
    }

    @objc func declinePayment(_: IconLabelButton) {
        selectionDelegate?.declinePayment(for: self)
    }
}
