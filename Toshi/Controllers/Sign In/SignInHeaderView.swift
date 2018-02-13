import Foundation
import UIKit
import TinyConstraints

final class SignInHeaderView: UIView {
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = Localized("passphrase_sign_in_title")
        view.textAlignment = .center
        view.textColor = Theme.darkTextColor
        view.font = Theme.preferredTitle1()
        view.adjustsFontForContentSizeCategory = true
        view.numberOfLines = 0
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        titleLabel.edges(to: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
