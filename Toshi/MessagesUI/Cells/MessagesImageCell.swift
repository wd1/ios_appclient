import Foundation
import UIKit
import TinyConstraints

class MessagesImageCell: MessagesBasicCell {

    static let reuseIdentifier = "MessagesImageCell"

    var messageImage: UIImage? {
        didSet {
            guard let messageImage = messageImage else {
                heightConstraint?.isActive = false
                heightConstraint = nil

                return
            }

            messageImageView.image = messageImage

            let aspectRatio: CGFloat = messageImage.size.height / messageImage.size.width

            heightConstraint?.isActive = false
            heightConstraint = messageImageView.height(to: messageImageView, messageImageView.widthAnchor, multiplier: aspectRatio, priority: .defaultHigh)
        }
    }

    private(set) lazy var messageImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit

        return view
    }()

    private var heightConstraint: NSLayoutConstraint?

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bubbleView.insertSubview(messageImageView, belowSubview: messagesCornerView)
        messageImageView.edges(to: bubbleView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        messageImageView.image = nil
    }
}
