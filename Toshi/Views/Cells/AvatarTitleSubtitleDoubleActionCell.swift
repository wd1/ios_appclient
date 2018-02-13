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

final class AvatarTitleSubtitleDoubleActionCell: BasicTableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()

        leftImageView.image = nil
        titleTextField.text = nil
        subtitleLabel.text = nil
        detailsLabel.text = nil
        secondActionButton.setImage(nil, for: .normal)
        firstActionButton.setImage(nil, for: .normal)
    }

    override func addSubviewsAndConstraints() {
        contentView.addSubview(leftImageView)
        contentView.addSubview(titleTextField)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(detailsLabel)
        contentView.addSubview(secondActionButton)
        contentView.addSubview(firstActionButton)

        setupLeftImageView()
        setupActionsButtons()
        setupTitleTextField()
        setupSubtitleLabel()
    }

    private func setupLeftImageView() {
        leftImageView.size(CGSize(width: BasicTableViewCell.imageSize, height: BasicTableViewCell.imageSize), priority: .required)
        leftImageView.centerY(to: contentView)
        leftImageView.left(to: contentView, offset: BasicTableViewCell.horizontalMargin, priority: .required)
        leftImageView.top(to: contentView, offset: BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)
        leftImageView.bottom(to: contentView, offset: -BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)
    }

    private func setupTitleTextField() {
        titleTextField.top(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        titleTextField.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin)
        titleTextField.rightToLeft(of: firstActionButton, offset: -BasicTableViewCell.interItemMargin)
        titleTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupSubtitleLabel() {
        subtitleLabel.topToBottom(of: titleTextField, offset: BasicTableViewCell.smallVerticalMargin)
        subtitleLabel.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin)
        subtitleLabel.rightToLeft(of: firstActionButton, offset: -BasicTableViewCell.interItemMargin)
        subtitleLabel.bottom(to: contentView, offset: -BasicTableViewCell.verticalMargin)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupActionsButtons() {
        secondActionButton.right(to: self, offset: -BasicTableViewCell.horizontalMargin)
        secondActionButton.centerY(to: self)
        secondActionButton.addTarget(self, action: #selector(didTapSecondButton(_:)), for: .touchUpInside)

        firstActionButton.rightToLeft(of: secondActionButton)
        firstActionButton.centerY(to: self)
        firstActionButton.addTarget(self, action: #selector(didTapFirstButton(_:)), for: .touchUpInside)
    }

    @objc private func didTapSecondButton(_ button: UIButton) {
        actionDelegate?.didTapSecondActionButton(self)
    }

    @objc private func didTapFirstButton(_ button: UIButton) {
        actionDelegate?.didTapFirstActionButton(self)
    }
}
