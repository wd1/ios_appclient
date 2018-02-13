import Foundation
import UIKit

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {

        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return ceil(boundingBox.height)
    }
}

extension NSAttributedString {

    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.width)
    }
}

extension CGFloat {
    
    func clamp(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(range.upperBound, Swift.max(range.lowerBound, self))
    }
}

extension String {

    var hasEmojiOnly: Bool {
        var emojiOnly = false

        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600 ... 0x1F64F, // Emoticons
                 0x1F300 ... 0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680 ... 0x1F6FF, // Transport and Map
                 0x2600 ... 0x26FF, // Misc symbols
                 0x2700 ... 0x27BF, // Dingbats
                 0xFE00 ... 0xFE0F: // Variation Selectors
                emojiOnly = true
            default:
                emojiOnly = false
            }
        }

        return emojiOnly
    }

    var emojiVisibleLength: Int {
        var count = 0

        enumerateSubstrings(in: startIndex ..< endIndex, options: .byComposedCharacterSequences) { _, _, _, _  in
            count += 1
        }

        return count
    }
}

extension UIView {

    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath

        if let mask = self.layer.mask as? CAShapeLayer {
            mask.path = path
        } else {
            let mask = CAShapeLayer()
            mask.path = path
            layer.mask = mask
        }

        setNeedsDisplay()
    }
}

extension UIViewAnimationOptions {

    static var easeInFromCurrentStateWithUserInteraction: UIViewAnimationOptions {
        return [.curveEaseIn, .beginFromCurrentState, .allowUserInteraction]
    }

    static var easeOutFromCurrentStateWithUserInteraction: UIViewAnimationOptions {
        return [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
    }

    static var easeInOutFromCurrentStateWithUserInteraction: UIViewAnimationOptions {
        return [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
    }
}

extension UIImageView {

    func duplicate() -> UIImageView? {
        guard let image = image?.copy() as? UIImage else { return nil }

        return UIImageView(image: image)
    }

    func contentModeAwareImageSize() -> CGSize? {
        guard let image = image else { return nil }
        let actualSize = image.size

        switch contentMode {
        case .scaleAspectFill:

            let scale = max(frame.size.width / actualSize.width, frame.size.height / actualSize.height)
            return CGSize(width: actualSize.width * scale, height: actualSize.height * scale)

        case .scaleAspectFit:

            let scale = min(frame.size.width / actualSize.width, frame.size.height / actualSize.height)
            return CGSize(width: actualSize.width * scale, height: actualSize.height * scale)

        default:
            return nil
        }
    }
}

extension UIBarButtonItem {
    
    static var back: UIBarButtonItem {
        let item = UIBarButtonItem()
        item.title = Localized("nav_bar_back")

        return item
    }
}

func Localized(_ key: String, tableName: String? = nil, bundle: Bundle = Bundle.main, value: String? = nil, comment: String? = nil) -> String {
    return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value ?? "", comment: comment ?? "")
}

func LocalizedPlural(_ key: String, for count: Int, tableName: String? = nil, bundle: Bundle = Bundle.main, value: String? = nil, comment: String? = nil) -> String {
    let format = NSLocalizedString(key, comment: comment ?? "")
    
    return String.localizedStringWithFormat(format, count)
}
