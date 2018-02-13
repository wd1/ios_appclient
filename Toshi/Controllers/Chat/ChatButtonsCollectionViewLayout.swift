import Foundation
import UIKit

final class ChatButtonsViewLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        
        minimumInteritemSpacing = 5
        minimumLineSpacing = 0
        estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        scrollDirection = .horizontal
        sectionInset = .zero
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let view = collectionView, let attributes = super.layoutAttributesForElements(in: CGRect(origin: .zero, size: view.contentSize))?.flatMap({ $0.copy() as? UICollectionViewLayoutAttributes }), attributes.count > 0 else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        var leftInset: CGFloat = 0
        let totalWidth: CGFloat = UIScreen.main.bounds.width - (view.contentInset.left + view.contentInset.right)
        let contentWidth: CGFloat = attributes.map { $0.frame.width }.reduce(0, +)
        let paddedContentWidth: CGFloat = contentWidth + CGFloat(attributes.count - 1) * minimumInteritemSpacing
        
        if paddedContentWidth < totalWidth {
            leftInset = totalWidth - paddedContentWidth
        }
        
        attributes.forEach {
            $0.frame.origin.x = leftInset
            leftInset += $0.frame.width + minimumInteritemSpacing
        }
        
        return attributes
    }
}
