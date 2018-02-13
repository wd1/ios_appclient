import Foundation
import UIKit

final class SignInLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        var newAttributes: [UICollectionViewLayoutAttributes] = []
        var marginLeft = sectionInset.left

        attributes?.forEach {
            let attribute = $0
            
            if attribute.frame.origin.x == sectionInset.left {
                marginLeft = sectionInset.left
            } else {
                var frame = attribute.frame
                frame.origin.x = marginLeft
                attribute.frame = frame
            }
            marginLeft += attribute.frame.size.width + minimumInteritemSpacing
            newAttributes.append(attribute)
        }
        
        return newAttributes
    }
}
