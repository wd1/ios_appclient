import Foundation
import UIKit
import TinyConstraints

final class MessagesErrorView: UIView {
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "error")
        view.contentMode = .scaleAspectFit
        
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        
        imageView.size(CGSize(width: 24, height: 24))
        imageView.left(to: self, offset: 6)
        imageView.centerY(to: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
