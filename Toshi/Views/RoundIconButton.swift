import Foundation
import UIKit

class RoundIconButton: UIControl {

    private lazy var circle: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.tintColor
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var icon: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = false

        return view
    }()

    convenience init(imageName: String, circleDiameter: CGFloat) {
        self.init(frame: .zero)

        circle.layer.cornerRadius = circleDiameter / 2
        addSubview(circle)

        circle.size(CGSize(width: circleDiameter, height: circleDiameter))
        circle.center(in: self)

        icon.image = UIImage(named: imageName)
        addSubview(icon)

        icon.center(in: self)
    }

    override var isEnabled: Bool {
        didSet {
            transform = isEnabled ? .identity : CGAffineTransform(scaleX: 0.5, y: 0.5)
            alpha = isEnabled ? 1 : 0

            circle.backgroundColor = isEnabled ? Theme.tintColor : Theme.greyTextColor
        }
    }
}
