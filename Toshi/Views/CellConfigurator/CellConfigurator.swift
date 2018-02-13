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

class CellConfigurator {
    func configureCell(_ cell: UITableViewCell, with cellData: TableCellData) {
        guard let cell = cell as? BasicTableViewCell else { return }

        if cellData.components.contains(.title) {
            if cellData.isPlaceholder {
                cell.titleTextField.placeholder = cellData.title
            } else {
                cell.titleTextField.text = cellData.title
            }
        }

        if cellData.components.contains(.subtitle) {
            cell.subtitleLabel.text = cellData.subtitle
        }

        if cellData.components.contains(.switchControl) {
            cell.switchControl.isOn = (cellData.switchState == true)
        }

        if cellData.components.contains(.details) {
            cell.detailsLabel.text = cellData.details
        }

        if cellData.components.contains(.topDetails) {
            cell.detailsLabel.text = cellData.topDetails
        }

        if cellData.components.contains(.leftImage) {
            cell.leftImageView.image = cellData.leftImage

            if let leftImagePath = cellData.leftImagePath {
                AvatarManager.shared.avatar(for: leftImagePath, completion: { [weak self] image, path in
                    if leftImagePath == path {
                        cell.leftImageView.image = image
                    }
                })
            }
        }

        if cellData.components.contains(.doubleImage) {
            cell.doubleImageView.setImages(cellData.doubleImage)
        }

        if cellData.components.contains(.doubleAction) {
            cell.firstActionButton.setImage(cellData.doubleActionImages?.firstImage, for: .normal)
            cell.secondActionButton.setImage(cellData.doubleActionImages?.secondImage, for: .normal)
        }

        if cellData.components.contains(.badge) {
            cell.badgeView.isHidden = false
            cell.badgeLabel.text = cellData.badgeText
        } else {
            cell.badgeLabel.text = nil
            cell.badgeView.isHidden = true
        }
    }

    func cellIdentifier(for components: TableCellDataComponents) -> String {
        var reuseIdentifier = TitleCell.reuseIdentifier

        if components.contains(.doubleImage) {
            reuseIdentifier = DoubleAvatarTitleSubtitleCell.reuseIdentifier
        } else if components.contains(.titleSubtitleSwitchControlLeftImage) {
            reuseIdentifier = AvatarTitleSubtitleSwitchCell.reuseIdentifier
        } else if components.contains(.titleSubtitleDetailsLeftImageBadge) {
            reuseIdentifier = AvatarTitleSubtitleDetailsBadgeCell.reuseIdentifier
        } else if components.contains(.titleSubtitleLeftImageTopDetails) {
            reuseIdentifier = AvatarTitleSubtitleDetailsBadgeCell.reuseIdentifier
        } else if components.contains(.titleSubtitleDetailsLeftImage) {
            reuseIdentifier = AvatarTitleSubtitleDetailsCell.reuseIdentifier
        } else if components.contains(.leftImageTitleSubtitleDoubleAction) {
            reuseIdentifier = AvatarTitleSubtitleDoubleActionCell.reuseIdentifier
        } else if components.contains(.titleSubtitleLeftImage) {
            reuseIdentifier = AvatarTitleSubtitleCell.reuseIdentifier
        } else if components.contains(.titleSubtitleSwitchControl) {
            reuseIdentifier = TitleSubtitleSwitchCell.reuseIdentifier
        } else if components.contains(.titleSwitchControl) {
            reuseIdentifier = TitleSwitchCell.reuseIdentifier
        } else if components.contains(.titleDetailsLeftImage) {
            reuseIdentifier = AvatarTitleDetailsCell.reuseIdentifier
        } else if components.contains(.titleLeftImage) {
            reuseIdentifier = AvatarTitleCell.reuseIdentifier
        } else if components.contains(.titleSubtitle) {
            reuseIdentifier = TitleSubtitleCell.reuseIdentifier
        }

        return reuseIdentifier
    }
}
