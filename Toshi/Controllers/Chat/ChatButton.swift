import UIKit

final class ChatButton: UIButton {

    var title: String? {
        didSet {
            buttonTitleLabel.text = title
        }
    }

    var shouldShowArrow: Bool = false {
        didSet {
            arrowImageView.isHidden = !shouldShowArrow

            if shouldShowArrow {
                titleToRightConstraint?.isActive = false
                titleToArrowConstraint?.isActive = true
            } else {
                titleToArrowConstraint?.isActive = false
                titleToRightConstraint?.isActive = true
            }
        }
    }

    var leftImage: UIImage? {
        didSet {
            if let image = leftImage {
                leftImageView.image = image
                leftImageView.isHidden = false

                titleToLeftConstraint?.isActive = false
                titleToLeftImageConstraint?.isActive = true

                leftImageWidthConstraint?.constant = image.size.width
                leftImageHeightConstraint?.constant = image.size.height
            } else {
                leftImageView.isHidden = true

                titleToLeftConstraint?.isActive = true
                titleToLeftImageConstraint?.isActive = false

                leftImageWidthConstraint?.constant = 0
                leftImageHeightConstraint?.constant = 0
            }
        }
    }

    private lazy var buttonTitleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredRegular()
        view.textColor = Theme.tintColor
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "chat-buttons-arrow")?.withRenderingMode(.alwaysTemplate)
        view.tintColor = Theme.tintColor
        view.isHidden = true

        return view
    }()

    private lazy var leftImageView: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        view.tintColor = Theme.tintColor

        return view
    }()

    private var titleToLeftConstraint: NSLayoutConstraint?
    private var titleToLeftImageConstraint: NSLayoutConstraint?

    private var titleToRightConstraint: NSLayoutConstraint?
    private var titleToArrowConstraint: NSLayoutConstraint?

    private var leftImageHeightConstraint: NSLayoutConstraint?
    private var leftImageWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.borderColor = Theme.tintColor.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 18
        clipsToBounds = true

        let layoutGuide = UILayoutGuide()

        addLayoutGuide(layoutGuide)

        addSubview(leftImageView)
        addSubview(buttonTitleLabel)
        addSubview(arrowImageView)

        layoutGuide.centerX(to: self)
        layoutGuide.top(to: self)
        layoutGuide.bottom(to: self)
        layoutGuide.left(to: self, relation: .equalOrGreater)
        layoutGuide.right(to: self, relation: .equalOrLess)

        leftImageView.centerY(to: layoutGuide)
        leftImageView.left(to: layoutGuide, offset: 15)
        leftImageHeightConstraint = leftImageView.height(0)
        leftImageWidthConstraint = leftImageView.width(0)

        buttonTitleLabel.top(to: layoutGuide, offset: 8)
        buttonTitleLabel.bottom(to: layoutGuide, offset: -8)

        titleToLeftConstraint = buttonTitleLabel.left(to: layoutGuide, offset: 15)
        titleToLeftImageConstraint = buttonTitleLabel.leftToRight(of: leftImageView, offset: 5, isActive: false)

        titleToRightConstraint = buttonTitleLabel.right(to: layoutGuide, offset: -15)
        titleToArrowConstraint = buttonTitleLabel.rightToLeft(of: arrowImageView, offset: -5, isActive: false)

        arrowImageView.centerY(to: layoutGuide)
        arrowImageView.right(to: layoutGuide, offset: -15)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTintColor(_ color: UIColor) {
        layer.borderColor = color.cgColor
        arrowImageView.tintColor = color
        leftImageView.tintColor = color
        buttonTitleLabel.textColor = color
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        buttonTitleLabel.font = Theme.preferredRegular()
    }
}
