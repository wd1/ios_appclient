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

final class StatusCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setTextLabelStyle()
        setupAppearence()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        //re-set the label text style to support dynamic type
        setTextLabelStyle()
    }

    private func setTextLabelStyle() {
        textLabel?.textAlignment = .center
        textLabel?.textColor = Theme.mediumTextColor
        textLabel?.font = Theme.preferredFootnote()

        textLabel?.adjustsFontForContentSizeCategory = true
    }

    private func setupAppearence() {
        textLabel?.numberOfLines = 0
        selectionStyle = .none
    }
}
