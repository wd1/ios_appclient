import Foundation
import UIKit
import TinyConstraints

class OpenURLButton: UIControl {

    private lazy var titleLabel: UILabel = UILabel()
    private lazy var chevron: UIImageView = UIImageView(image: UIImage(named: "chevron"))

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        addSubview(chevron)

        let margin: CGFloat = 12.0

        titleLabel.top(to: self, offset: margin)
        titleLabel.left(to: self, offset: margin)
        titleLabel.bottom(to: self, offset: -margin)
        titleLabel.rightToLeft(of: chevron, offset: margin)

        chevron.height(14)
        chevron.width(14)
        chevron.centerY(to: self)
        chevron.right(to: self, offset: -margin)
    }

    func setAttributedTitle(_ attributedText: NSAttributedString?) {
        titleLabel.attributedText = attributedText
    }
}
