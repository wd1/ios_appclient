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

final class TitleSubtitleSwitchCell: BasicTableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()

        titleTextField.text = nil
        subtitleLabel.text = nil
        switchControl.setOn(false, animated: false)
    }

    override func addSubviewsAndConstraints() {
        contentView.addSubview(titleTextField)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(switchControl)

        setupTitleTextField()
        setupSubtitleLabel()
        setupSwitchControl()
    }

    private func setupTitleTextField() {
        titleTextField.top(to: contentView, offset: BasicTableViewCell.verticalMargin)
        titleTextField.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        titleTextField.rightToLeft(of: switchControl, offset: -BasicTableViewCell.horizontalMargin)
        titleTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupSubtitleLabel() {
        subtitleLabel.topToBottom(of: titleTextField, offset: BasicTableViewCell.smallVerticalMargin)
        subtitleLabel.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        subtitleLabel.rightToLeft(of: switchControl, offset: -BasicTableViewCell.horizontalMargin)
        subtitleLabel.bottom(to: contentView, offset: -BasicTableViewCell.verticalMargin)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupSwitchControl() {
        switchControl.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        switchControl.centerY(to: contentView)
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        titleTextField.font = Theme.preferredRegular()
        subtitleLabel.font = Theme.preferredRegularSmall()
    }
}
