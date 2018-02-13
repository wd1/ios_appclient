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

class BrowseEntityCollectionViewCell: UICollectionViewCell {

    private(set) lazy var avatarImageView: AvatarImageView = AvatarImageView()

    private(set) lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.medium(size: 15)
        label.textColor = Theme.darkTextColor
        label.numberOfLines = 2

        return label
    }()

    private lazy var downloadOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Browse entity cell avatar download queue"

        return queue
    }()

    var imageViewPath: String? {
        didSet {
            retrieveAvatar()
        }
    }

    private(set) lazy var ratingView = RatingView(numberOfStars: 5)

    private(set) lazy var verticalPositionGuide = UILayoutGuide()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = nil
        isOpaque = false

        addSubviewsAndConstraints()
    }

    private func addSubviewsAndConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addLayoutGuide(verticalPositionGuide)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(ratingView)

        let size = CGSize(width: floor((UIScreen.main.bounds.width - 10) / 3.5), height: 180)

        verticalPositionGuide.width(size.width)
        verticalPositionGuide.height(size.height)
        verticalPositionGuide.edges(to: contentView, insets: UIEdgeInsets(top: 67, left: 0, bottom: 0, right: 0))

        avatarImageView.top(to: verticalPositionGuide, offset: 5)
        avatarImageView.left(to: verticalPositionGuide, offset: 7)
        avatarImageView.right(to: verticalPositionGuide, offset: -7)
        avatarImageView.height(to: avatarImageView, avatarImageView.widthAnchor)

        nameLabel.topToBottom(of: avatarImageView, offset: 5)
        nameLabel.left(to: verticalPositionGuide, offset: 7)
        nameLabel.right(to: verticalPositionGuide, offset: -7)
        nameLabel.height(36)

        ratingView.topToBottom(of: nameLabel, offset: 5)
        ratingView.left(to: verticalPositionGuide, offset: 7)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        downloadOperationQueue.cancelAllOperations()

        nameLabel.text = nil
        avatarImageView.image = nil
        ratingView.set(rating: 0)
    }

    private func retrieveAvatar() {

        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self] in

            guard operation.isCancelled == false else { return }
            guard let path = self?.imageViewPath else { return }

            AvatarManager.shared.avatar(for: path) { [weak self] image, downloadedImagePath in

                DispatchQueue.main.async {
                    guard operation.isCancelled == false else { return }
                    guard let path = self?.imageViewPath else { return }

                    if downloadedImagePath == path {
                        self?.avatarImageView.image = image
                    }
                }
            }
        }

        downloadOperationQueue.addOperation(operation)
    }
}
