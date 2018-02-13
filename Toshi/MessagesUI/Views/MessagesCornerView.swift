import Foundation
import UIKit

enum MessagesCornerType {
    case cornerMiddleOutgoing
    case cornerMiddleOutlineOutgoing
    case cornerMiddleOutline
    case cornerMiddle
    case cornerTopOutgoing
    case cornerTopOutlineOutgoing
    case cornerTopOutline
    case cornerTop
}

class MessagesCornerView: UIImageView {

    private lazy var cornerMiddleOutgoingImage: UIImage? = self.stretchableImage(with: "corner-middle-outgoing")
    private lazy var cornerMiddleOutlineOutgoingImage: UIImage? = self.stretchableImage(with: "corner-middle-outline-outgoing")
    private lazy var cornerMiddleOutlineImage: UIImage? = self.stretchableImage(with: "corner-middle-outline")
    private lazy var cornerMiddleImage: UIImage? = self.stretchableImage(with: "corner-middle")
    private lazy var cornerTopOutgoingImage: UIImage? = self.stretchableImage(with: "corner-top-outgoing")
    private lazy var cornerTopOutlineOutgoingImage: UIImage? = self.stretchableImage(with: "corner-top-outline-outgoing")
    private lazy var cornerTopOutlineImage: UIImage? = self.stretchableImage(with: "corner-top-outline")
    private lazy var cornerTopImage: UIImage? = self.stretchableImage(with: "corner-top")

    var type: MessagesCornerType? {
        didSet {
            guard let type = type else {
                image = nil
                return
            }

            switch type {
            case .cornerMiddleOutgoing:
                image = cornerMiddleOutgoingImage
            case .cornerMiddleOutlineOutgoing:
                image = cornerMiddleOutlineOutgoingImage
            case .cornerMiddleOutline:
                image = cornerMiddleOutlineImage
            case .cornerMiddle:
                image = cornerMiddleImage
            case .cornerTopOutgoing:
                image = cornerTopOutgoingImage
            case .cornerTopOutlineOutgoing:
                image = cornerTopOutlineOutgoingImage
            case .cornerTopOutline:
                image = cornerTopOutlineImage
            case .cornerTop:
                image = cornerTopImage
            }
        }
    }

    func stretchableImage(with name: String) -> UIImage? {
        return UIImage(named: name)?.stretchableImage(withLeftCapWidth: 18, topCapHeight: 18)
    }

    func setImage(for positionType: MessagePositionType, isOutGoing: Bool, isPayment: Bool) {

        if isPayment {
            switch positionType {
            case .single, .top:
                type = isOutGoing ? .cornerTopOutlineOutgoing : .cornerTopOutline
            case .middle, .bottom:
                type = isOutGoing ? .cornerMiddleOutlineOutgoing : .cornerMiddleOutline
            }
        } else {
            switch positionType {
            case .single, .top:
                type = isOutGoing ? .cornerTopOutgoing : .cornerTop
            case .middle, .bottom:
                type = isOutGoing ? .cornerMiddleOutgoing : .cornerMiddle
            }
        }
    }
}
