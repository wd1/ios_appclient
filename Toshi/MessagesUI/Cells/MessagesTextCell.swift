import Foundation
import UIKit
import TinyConstraints

class MessagesTextCell: MessagesBasicCell {

    static let reuseIdentifier = "MessagesTextCell"

    var messageText: String? {
        didSet {
            if let messageText = messageText, messageText.hasEmojiOnly, messageText.emojiVisibleLength <= 3 {
                textView.text = messageText
                bubbleView.backgroundColor = nil
                textView.font = Theme.emoji()
            } else {
                let usernameLinkColor = isOutGoing ? Theme.lightTextColor : Theme.tintColor
                textView.attributedText = TextTransformer.attributedUsernameString(to: messageText, textColor: messageColor, linkColor: usernameLinkColor, font: Theme.preferredRegularText())
            }
        }
    }

    private var messageColor: UIColor {
        return isOutGoing ? .white : .black
    }

    private lazy var textView: UITextView = {
        let view = UITextView()
        view.font = Theme.preferredRegularText()
        view.adjustsFontForContentSizeCategory = true
        view.dataDetectorTypes = [.link]
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.contentMode = .topLeft
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.maximumNumberOfLines = 0

        view.linkTextAttributes = [NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue]

        return view
    }()

    override var isOutGoing: Bool {
        didSet {
            super.isOutGoing = isOutGoing

            textView.textColor = isOutGoing ? .white : .black
            bubbleView.backgroundColor = isOutGoing ? Theme.tintColor : Theme.incomingMessageBackgroundColor
        }
    }
    
    override func showSentError(_ show: Bool, animated: Bool) {
        super.showSentError(show, animated: animated)
        textView.isUserInteractionEnabled = !show
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bubbleView.addSubview(textView)
        textView.edges(to: bubbleView, insets: UIEdgeInsets(top: 8, left: 12, bottom: -8, right: -12))
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        if let text = textView.attributedText?.mutableCopy() as? NSMutableAttributedString {
            let range = NSRange(location: 0, length: text.string.length)

            text.removeAttribute(.link, range: range)
            text.removeAttribute(.foregroundColor, range: range)
            text.removeAttribute(.underlineStyle, range: range)

            textView.attributedText = text
        }
        
        textView.font = Theme.preferredRegularText()
        textView.adjustsFontForContentSizeCategory = true
        textView.text = nil
    }
}
