import Foundation
import UIKit
import TinyConstraints

final class SignInCell: UICollectionViewCell {

    static let reuseIdentifier: String = "SignInCell"
    private(set) var text: String = ""
    private(set) var match: String?
    private(set) var isFirstAndOnly: Bool = false
    private var caretViewLeftConstraint: NSLayoutConstraint?
    private var caretViewRightConstraint: NSLayoutConstraint?
    private let caretKerning: CGFloat = 1

    private lazy var backgroundImageView = UIImageView(image: UIImage(named: "sign-in-cell-background")?.stretchableImage(withLeftCapWidth: 18, topCapHeight: 18))
    private lazy var passwordLabel: UILabel = {
        let view = UILabel()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private(set) var caretView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.tintColor
        view.layer.cornerRadius = 1
        view.clipsToBounds = true

        return view
    }()

    override var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            self.isActive = isSelected
        }
    }

    var isActive: Bool = false {
        didSet {
            caretView.alpha = isActive ? 1 : 0
            backgroundImageView.isHidden = isActive

            if let match = match, !isActive {
                updateAttributedText(match, with: match)

                contentView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)

                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 100, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    self.contentView.transform = .identity
                }, completion: nil)

            } else {
                updateAttributedText(text, with: match)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = nil
        contentView.isOpaque = false

        contentView.addSubview(backgroundImageView)
        contentView.addSubview(passwordLabel)
        passwordLabel.addSubview(caretView)

        backgroundImageView.edges(to: contentView)
        backgroundImageView.height(36, relation: .equalOrGreater)
        backgroundImageView.width(36, relation: .equalOrGreater)

        passwordLabel.edges(to: contentView, insets: UIEdgeInsets(top: 2, left: 13 + caretKerning, bottom: -4, right: -13))

        caretViewLeftConstraint = caretView.left(to: passwordLabel)
        caretViewRightConstraint = caretView.right(to: passwordLabel, isActive: false)
        caretView.centerY(to: passwordLabel)
        caretView.width(2)
        caretView.height(21)

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.caretView.isHidden = !self.caretView.isHidden
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String, with match: String? = nil, isFirstAndOnly: Bool = false) {
        self.text = text
        self.match = match
        self.isFirstAndOnly = isFirstAndOnly

        updateAttributedText(text, with: match)
    }

    func updateAttributedText(_ text: String, with match: String? = nil) {
        let emptyString = isFirstAndOnly ? Localized("passphrase_sign_in_placeholder") : ""
        let string = text.isEmpty ? emptyString : match ?? text
        let attributedText = NSMutableAttributedString(string: string, attributes: [.font: Theme.preferredRegular(), .foregroundColor: Theme.greyTextColor])

        if let match = match, let matchingRange = (match as NSString?)?.range(of: text, options: [.caseInsensitive, .anchored]) {
            attributedText.addAttribute(.foregroundColor, value: Theme.darkTextColor, range: matchingRange)
            attributedText.addAttribute(.kern, value: caretKerning, range: NSRange(location: matchingRange.length - 1, length: 1))

            caretViewRightConstraint?.isActive = false
            caretViewLeftConstraint?.isActive = true
            caretViewLeftConstraint?.constant = round(matchingFrame(for: matchingRange, in: attributedText).width) - caretKerning - 1
        } else if text.isEmpty {
            caretViewRightConstraint?.isActive = false
            caretViewLeftConstraint?.isActive = true
            caretViewLeftConstraint?.constant = 0
        } else {
            let errorRange = NSRange(location: 0, length: attributedText.length)
            attributedText.addAttribute(.foregroundColor, value: Theme.errorColor, range: errorRange)

            caretViewLeftConstraint?.isActive = false
            caretViewRightConstraint?.isActive = true
        }

        passwordLabel.attributedText = attributedText
    }

    private func matchingFrame(for range: NSRange, in attributedText: NSAttributedString) -> CGRect {
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: passwordLabel.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()

        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)

        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}
