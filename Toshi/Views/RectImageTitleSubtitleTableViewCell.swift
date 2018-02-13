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

final class RectImageTitleSubtitleTableViewCell: UITableViewCell {

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = Theme.preferredSemibold()
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        return titleLabel
    }()

    lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()

        subtitleLabel.font = Theme.preferredRegularSmall()
        subtitleLabel.textColor = Theme.lightGreyTextColor
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)

        return subtitleLabel
    }()

    lazy var leftImageView: UIImageView = {
        let leftImageView = UIImageView()
        leftImageView.contentMode = .scaleAspectFit

        return leftImageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        addSubviewsAndConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        leftImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    private func addSubviewsAndConstraints() {
        contentView.addSubview(leftImageView)
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center

        contentView.addSubview(stackView)

        stackView.centerY(to: contentView)
        stackView.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin, priority: .required)
        stackView.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin, priority: .required)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        setupLeftImageView()
    }

    private func setupLeftImageView() {
        leftImageView.size(CGSize(width: 78, height: 78))
        leftImageView.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        leftImageView.top(to: contentView, offset: BasicTableViewCell.imageMargin)
        leftImageView.bottom(to: contentView, offset: -BasicTableViewCell.imageMargin)
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        titleLabel.font = Theme.preferredRegular()
        subtitleLabel.font = Theme.preferredRegularSmall()
    }
}
