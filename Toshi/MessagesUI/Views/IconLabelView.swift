import Foundation
import UIKit
import TinyConstraints

class IconLabelView: UIView {

    private(set) lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.isUserInteractionEnabled = false

        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.isUserInteractionEnabled = false

        return view
    }()

    let topLayoutGuide = UILayoutGuide()
    let leftLayoutGuide = UILayoutGuide()
    let bottomLayoutGuide = UILayoutGuide()
    let rightLayoutGuide = UILayoutGuide()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addLayoutGuide(topLayoutGuide)
        addLayoutGuide(leftLayoutGuide)
        addLayoutGuide(bottomLayoutGuide)
        addLayoutGuide(rightLayoutGuide)

        addSubview(iconImageView)
        addSubview(titleLabel)

        topLayoutGuide.top(to: self)
        topLayoutGuide.left(to: self)
        topLayoutGuide.right(to: self)

        bottomLayoutGuide.left(to: self)
        bottomLayoutGuide.bottom(to: self)
        bottomLayoutGuide.right(to: self)
        bottomLayoutGuide.height(to: topLayoutGuide, topLayoutGuide.heightAnchor)

        leftLayoutGuide.topToBottom(of: topLayoutGuide)
        leftLayoutGuide.left(to: self)
        leftLayoutGuide.bottomToTop(of: bottomLayoutGuide)

        rightLayoutGuide.topToBottom(of: topLayoutGuide)
        rightLayoutGuide.right(to: self)
        rightLayoutGuide.bottomToTop(of: bottomLayoutGuide)
        rightLayoutGuide.width(to: leftLayoutGuide, leftLayoutGuide.widthAnchor)

        iconImageView.topToBottom(of: topLayoutGuide)
        iconImageView.leftToRight(of: leftLayoutGuide)
        iconImageView.bottomToTop(of: bottomLayoutGuide)

        titleLabel.topToBottom(of: topLayoutGuide)
        titleLabel.leftToRight(of: iconImageView, offset: 5)
        titleLabel.bottomToTop(of: bottomLayoutGuide)
        titleLabel.rightToLeft(of: rightLayoutGuide)
    }
}
