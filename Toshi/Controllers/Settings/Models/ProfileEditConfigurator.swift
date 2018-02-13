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

final class ProfileEditConfigurator {

    private var item: ProfileEditItem = ProfileEditItem(.none)

    init(item: ProfileEditItem) {
        self.item = item
    }

    func configure(cell: InputCell) {
        cell.selectionStyle = .none
        cell.titleLabel.text = item.titleText
        cell.textField.text = item.detailText
        cell.switchControl.isOn = item.switchMode

        cell.switchControl.isHidden = (item.type != ProfileEditItemType.visibility)
        cell.textField.isHidden = (item.type == ProfileEditItemType.visibility)
        cell.textField.autocapitalizationType = item.type.autocapitalizationType

        cell.updater = self
    }
}

extension ProfileEditConfigurator: InputCellUpdater {

    func inputDidUpdate(_ detailText: String?, _ switchMode: Bool) {
        item.update(detailText, switchMode)
    }
}
