// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import UIKit
import SweetUIKit

protocol BrowseCollectionViewCellSelectionDelegate: class {
    func seeAll(for contentSection: BrowseContentSection)
    func didSelectItem(at indexPath: IndexPath, collectionView: SectionedCollectionView)
}

class SectionedCollectionView: UICollectionView {
    var section: Int = 0
}

class BrowseCollectionViewCell: UICollectionViewCell {

    let horizontalInset: CGFloat = 10

    weak var collectionViewDelegate: BrowseCollectionViewCellSelectionDelegate?

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize

        return layout
    }()

    private(set) lazy var collectionView: SectionedCollectionView = {
        let view = SectionedCollectionView(frame: .zero, collectionViewLayout: self.layout)
        view.delaysContentTouches = false
        view.isPagingEnabled = false
        view.backgroundColor = nil
        view.isOpaque = false
        view.alwaysBounceHorizontal = true
        view.showsHorizontalScrollIndicator = true
        view.contentInset = UIEdgeInsets(top: 0, left: self.horizontalInset, bottom: 0, right: self.horizontalInset)
        view.delegate = self
        view.register(BrowseEntityCollectionViewCell.self)

        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredTitle2()
        view.textColor = Theme.darkTextColor
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    private lazy var seeAllButton: UIButton = {
        let view = UIButton()
        view.titleLabel?.font = Theme.preferredRegular()
        view.setTitleColor(Theme.tintColor, for: .normal)
        view.setTitle(Localized("browse-more-button"), for: .normal)
        view.addTarget(self, action: #selector(seeAllButtonTapped(_:)), for: .touchUpInside)
        view.titleLabel?.adjustsFontForContentSizeCategory = true

        return view
    }()

    lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor

        return view
    }()

    var contentSection: BrowseContentSection? {
        didSet {
            guard let contentSection = contentSection else { return }
            titleLabel.text = contentSection.title
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.clipsToBounds = true
        backgroundColor = Theme.viewBackgroundColor

        addSubviewsAndConstraints()
    }

    private func addSubviewsAndConstraints() {
        contentView.addSubview(collectionView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(seeAllButton)
        contentView.addSubview(divider)

        collectionView.edges(to: contentView)

        let collectionHeaderLayoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(collectionHeaderLayoutGuide)

        collectionHeaderLayoutGuide.height(50)
        collectionHeaderLayoutGuide.top(to: contentView)
        collectionHeaderLayoutGuide.left(to: contentView)
        collectionHeaderLayoutGuide.right(to: contentView)

        // We want the "More" button text to always be completely visible but never bigger
        seeAllButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        seeAllButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        // We want the title to break off when it becomes to big, but otherwise take the full available space
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        titleLabel.left(to: collectionHeaderLayoutGuide, offset: 15)
        titleLabel.centerY(to: collectionHeaderLayoutGuide)
        titleLabel.height(44)

        seeAllButton.leftToRight(of: titleLabel, offset: 10)
        seeAllButton.right(to: collectionHeaderLayoutGuide, offset: -15)
        seeAllButton.centerY(to: collectionHeaderLayoutGuide)

        divider.height(.lineHeight)
        divider.left(to: self, offset: 15, relation: .equalOrLess)
        divider.right(to: self)
        divider.bottom(to: contentView)
    }

    @objc func seeAllButtonTapped(_: UIButton) {
        guard let contentSection = contentSection else { return }

        collectionViewDelegate?.seeAll(for: contentSection)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = nil
    }
}

extension BrowseCollectionViewCell: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if let collectionView = collectionView as? SectionedCollectionView {
            collectionViewDelegate?.didSelectItem(at: indexPath, collectionView: collectionView)
        }
    }
}
