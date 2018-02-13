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

final class WalletItemCellConfigurator: CellConfigurator {

    override func configureCell(_ cell: UITableViewCell, with cellData: TableCellData) {
        super.configureCell(cell, with: cellData)

        guard let cell = cell as? BasicTableViewCell else { return }

        cell.detailsFont = Theme.preferredRegular()

        cell.titleTextField.setContentCompressionResistancePriority(.required, for: .horizontal)

        if cellData.components.contains(.topDetails) {
            cell.detailsLabel.textColor = Theme.darkTextColor
        } else {
            cell.detailsLabel.textColor = Theme.lightGreyTextColor
        }
    }
}
