import Foundation
import UIKit
import TinyConstraints

class LeftAlignedButton: UIControl {
    
    var icon: UIImage? {
        didSet {
            iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var titleColor: UIColor? {
        didSet {
            iconImageView.tintColor = titleColor
            titleLabel.textColor = titleColor
        }
    }
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredRegularMedium()
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        
        let iconSize: CGFloat = 48
        let margin: CGFloat = 16
        
        iconImageView.left(to: self, offset: margin)
        iconImageView.centerY(to: self)
        iconImageView.size(CGSize(width: iconSize, height: iconSize))
        
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = (iconSize / 2)
        
        titleLabel.edgesToSuperview(excluding: .left, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -margin))
        titleLabel.leftToRight(of: iconImageView, offset: 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
