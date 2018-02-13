import Foundation
import UIKit
import TinyConstraints

class MessagesStatusCell: MessagesBasicCell {

    static let reuseIdentifier = "MessagesStatusCell"

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
