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

import UIKit

class SearchResultCell: UITableViewCell {

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.textColor = Theme.darkTextColor
        view.font = Theme.preferredSemibold()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.textColor = Theme.greyTextColor
        view.font = Theme.preferredRegularSmall()
        view.adjustsFontForContentSizeCategory = true

        return view
    }()

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(separatorView)

        let margin: CGFloat = 16.0
        let interLabelMargin: CGFloat = 6.0
        let imageSize: CGFloat = 48.0
        let height: CGFloat = 24.0

        avatarImageView.size(CGSize(width: imageSize, height: imageSize))
        avatarImageView.centerY(to: contentView)
        avatarImageView.left(to: contentView, offset: margin)

        nameLabel.height(height, relation: .equalOrGreater)
        nameLabel.top(to: contentView, offset: margin)
        nameLabel.leftToRight(of: avatarImageView, offset: 10)
        nameLabel.right(to: contentView, offset: -margin)

        usernameLabel.height(height, relation: .equalOrGreater)
        usernameLabel.topToBottom(of: nameLabel)
        usernameLabel.leftToRight(of: avatarImageView, offset: 10)
        usernameLabel.right(to: contentView, offset: -margin)

        separatorView.height(.lineHeight)
        separatorView.topToBottom(of: usernameLabel, offset: interLabelMargin)
        separatorView.left(to: contentView, offset: margin)
        separatorView.bottom(to: contentView)
        separatorView.right(to: contentView, offset: -margin)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        usernameLabel.text = nil
        avatarImageView.image = nil
    }
}
