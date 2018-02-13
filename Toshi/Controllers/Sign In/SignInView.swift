import Foundation
import UIKit
import TinyConstraints

final class SignInView: UIView {
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.showsVerticalScrollIndicator = true
        view.delaysContentTouches = false
        view.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        
        return view
    }()
    
    private(set) lazy var contentView = UIView()
    
    private lazy var layout: SignInLayout = {
        let layout = SignInLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        
        return layout
    }()

    private(set) lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        view.backgroundColor = nil
        view.delaysContentTouches = false
        view.isScrollEnabled = false
        
        view.register(SignInCell.self, forCellWithReuseIdentifier: SignInCell.reuseIdentifier)
        
        return view
    }()
    
    private lazy var topBarBlur = UIVisualEffectView(effect: UIBlurEffect(style: .light))

    private(set) lazy var textField: DeletableTextField = {
        let view = DeletableTextField()
        view.font = Theme.regular(size: 15)
        view.textColor = Theme.darkTextColor
        view.returnKeyType = .next
        view.alpha = 0
        
        view.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        return view
    }()
    
    private var collectionViewHeightConstraint: NSLayoutConstraint?
    private var keyboardHeightConstraint: NSLayoutConstraint?
    
    private lazy var headerView: SignInHeaderView = SignInHeaderView()
    private(set) lazy var footerView: SignInFooterView = SignInFooterView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.viewBackgroundColor
        
        addSubview(textField)
        addSubview(scrollView)
        addSubview(topBarBlur)
        scrollView.addSubview(contentView)
        contentView.addSubview(collectionView)
        contentView.addSubview(headerView)
        contentView.addSubview(footerView)
        
        scrollView.edgesToSuperview(excluding: .bottom)
        keyboardHeightConstraint = scrollView.bottom(to: self)
        contentView.edges(to: scrollView)
        contentView.width(to: scrollView)
        
        headerView.top(to: contentView)
        headerView.left(to: contentView)
        headerView.right(to: contentView)
        
        collectionView.topToBottom(of: headerView, offset: 50)
        collectionView.left(to: contentView)
        collectionView.right(to: contentView)
        collectionViewHeightConstraint = collectionView.height(36)
        
        footerView.topToBottom(of: collectionView, offset: 5)
        footerView.left(to: contentView)
        footerView.right(to: contentView)
        footerView.bottom(to: contentView)
        
        textField.left(to: self)
        textField.bottom(to: self, offset: 0)
        textField.right(to: self)
        textField.height(44)
        
        topBarBlur.edgesToSuperview(excluding: .bottom)
        topBarBlur.height(64)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        textField.text = textField.text?.lowercased()
    }
    
    @objc func keyboardWillChangeFrame(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo, let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        keyboardHeightConstraint?.constant = endFrame.origin.y >= UIScreen.main.bounds.height ? 0 : -endFrame.size.height
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionViewHeightConstraint?.constant = collectionView.contentSize.height
        updateSignInButton()
    }
    
    private func updateSignInButton() {
        let indexPaths = collectionView.indexPathsForVisibleItems.sorted {$0.item < $1.item}
        let cells = indexPaths.flatMap { collectionView.cellForItem(at: $0) as? SignInCell }
        let matches = cells.flatMap { $0.match }
        let errors = cells.filter { $0.match == nil && !$0.text.isEmpty }
        
        footerView.numberOfMatches = matches.count
        footerView.numberOfErrors = errors.count
    }
}
