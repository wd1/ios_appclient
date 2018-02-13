import Foundation
import UIKit
import TinyConstraints

class IconLabelButton: UIControl {

    private lazy var iconLabelView: IconLabelView = {
        let view = IconLabelView()
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor
        view.isUserInteractionEnabled = false

        return view
    }()

    var title: String? {
        didSet {
            iconLabelView.titleLabel.text = title
        }
    }

    var icon: UIImage? {
        didSet {
            iconLabelView.iconImageView.image = icon
        }
    }

    var color: UIColor? {
        didSet {
            iconLabelView.titleLabel.textColor = color
            iconLabelView.iconImageView.tintColor = color
        }
    }

    var font: UIFont? {
        didSet {
            iconLabelView.titleLabel.font = font
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconLabelView.titleLabel.font = UIFont(name: "Helvetica", size: 15)

        addSubview(divider)
        addSubview(iconLabelView)

        divider.top(to: self)
        divider.left(to: self)
        divider.right(to: self)
        divider.height(.lineHeight)

        iconLabelView.edges(to: self)
    }

    override var isHighlighted: Bool {
        didSet {
            iconLabelView.alpha = isHighlighted ? 0.5 : 1
        }
    }
}
