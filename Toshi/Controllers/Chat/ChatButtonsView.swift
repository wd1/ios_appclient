import Foundation
import UIKit
import TinyConstraints

protocol ChatButtonsSelectionDelegate: class {
    func didSelectButton(at indexPath: IndexPath)
}

final class ChatButtonsView: UIView {
    static let height: CGFloat = 54
    
    weak var delegate: ChatButtonsSelectionDelegate?
    private var heightConstraint: NSLayoutConstraint?
    
    var buttons: [SofaMessage.Button]? = [] {
        didSet {
            heightConstraint?.constant = buttons == nil ? 0 : ChatButtonsView.height
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    private(set) lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: ChatButtonsViewLayout())
        view.backgroundColor = .clear
        view.isOpaque = false
        view.delegate = self
        view.dataSource = self
        view.contentInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        view.alwaysBounceHorizontal = true
        
        view.register(ChatButtonsViewCell.self, forCellWithReuseIdentifier: ChatButtonsViewCell.reuseIdentifier)
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        heightConstraint = height(0)
        
        addSubview(collectionView)
        collectionView.edgesToSuperview(excluding: .bottom)
        collectionView.height(ChatButtonsView.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ChatButtonsView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectButton(at: indexPath)
    }
}

extension ChatButtonsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttons?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatButtonsViewCell.reuseIdentifier, for: indexPath)
        
        if let cell = cell as? ChatButtonsViewCell, let button = buttons?.element(at: indexPath.item) {
            cell.title = button.label
            cell.shouldShowArrow = button.type == .group
        }
        
        return cell
    }
}
