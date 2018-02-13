import Foundation
import UIKit
import TinyConstraints

final class ChatButtonsViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ChatButtonsViewCell"

    var title: String? {
        didSet {
            buttonView.title = title
        }
    }

    var shouldShowArrow: Bool = false {
        didSet {
            buttonView.shouldShowArrow = shouldShowArrow
        }
    }

    private lazy var buttonView: ChatButton = {
        let buttonView = ChatButton()

        buttonView.isUserInteractionEnabled = false
        
        return buttonView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(buttonView)

        buttonView.edges(to: contentView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        title = nil
        shouldShowArrow = false
    }
}
