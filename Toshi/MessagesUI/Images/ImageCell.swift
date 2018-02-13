import Foundation
import UIKit
import TinyConstraints

class ImageCell: UICollectionViewCell {
    static var reuseIdentifier = "ImageCell"

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return view
    }()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear

        contentView.addSubview(imageView)
        imageView.edges(to: contentView)
    }
}
