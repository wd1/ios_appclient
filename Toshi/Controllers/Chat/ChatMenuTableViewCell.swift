import Foundation
import UIKit
import TinyConstraints

final class ChatMenuTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "ChatMenuTableViewCell"
    
    private(set) lazy var bottomDivider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor
        
        return view
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = nil
        isOpaque = false
        
        contentView.addSubview(bottomDivider)
        bottomDivider.left(to: contentView)
        bottomDivider.bottom(to: contentView)
        bottomDivider.right(to: contentView)
        bottomDivider.height(.lineHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
